import Foundation
import Supabase
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var children: [ChildModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newChildName = ""
    @Published var newChildAge = ""
    @Published var newChildAgeGroup: LumaAgeGroup = .sixToEight
    @Published var selectedEmoji = ChildModel.defaultAvatarEmoji
    @Published var interests: [String] = []
    @Published var fears: [String] = []
    @Published var editingChild: ChildModel? = nil
    @Published var isEditSheetPresented = false
    @Published var selectedChildForDetail: ChildModel? = nil
    @Published var isShowingDetailSheet = false
    @Published var parentEmail: String = ""

    let availableEmojis = ChildModel.supportedAvatarEmojis
    private var lastChildrenFetchAt: Date?
    private let minChildrenFetchInterval: TimeInterval = 8
    private var isFetchingChildren = false

    func fetchChildren(forceRefresh: Bool = false) async {
        if isFetchingChildren {
            if !forceRefresh { return }
            // Güncelleme sonrası yenileme, halihazırda süren isteği bekleyip tekrar dener (üst süre ~6 sn).
            var waits = 0
            while isFetchingChildren, waits < 100 {
                try? await Task.sleep(nanoseconds: 60_000_000)
                waits += 1
            }
        }
        if !forceRefresh,
           let lastFetch = lastChildrenFetchAt,
           Date().timeIntervalSince(lastFetch) < minChildrenFetchInterval {
            return
        }

        isFetchingChildren = true
        let shouldManageLoadingState = !isLoading
        if shouldManageLoadingState {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isFetchingChildren = false
            if shouldManageLoadingState {
                isLoading = false
            }
        }

        if let user = OliaApp.supabase.auth.currentUser {
            parentEmail = user.email ?? "Ebeveyn"
            AppLogger.info("children.fetch.started", ["context": "ProfileViewModel"])
            do {
                let response = try await ChildrenAPIService.fetchChildren()
                children = response
                lastChildrenFetchAt = Date()
                AppLogger.info("children.fetch.completed", [
                    "context": "ProfileViewModel",
                    "count": "\(response.count)"
                ])
            } catch {
                AppLogger.error("children.fetch.failed", [
                    "context": "ProfileViewModel",
                    "error": String(describing: type(of: error))
                ])
                errorMessage = "Veriler alınırken bir hata oluştu: \(error.userFacingTurkishMessage)"
            }
        }
    }

    func addChild() async -> Bool {
        return await addChild(interests: interests, fears: fears)
    }

    /// Çocuk ekler; interests ve fears parametre olarak verilir (form anlık değerleri için).
    func addChild(interests currentInterests: [String], fears currentFears: [String]) async -> Bool {
        guard !newChildName.isEmpty else {
            errorMessage = "Lütfen isim alanını doldurun ve yaş aralığı seçin."
            return false
        }

        isLoading = true
        let ageInt = suggestedAge(for: newChildAgeGroup)
        let safeInterests = Self.sanitizeTagList(currentInterests)
        let safeFears = Self.sanitizeTagList(currentFears)

        do {
            AppLogger.info("children.create.request_sent", [:])
            _ = try await ChildrenAPIService.createChild(
                name: newChildName,
                age: ageInt,
                profile: nil,
                avatarEmoji: ChildModel.sanitizeAvatarEmoji(selectedEmoji),
                interests: safeInterests.isEmpty ? [] : safeInterests,
                fears: safeFears.isEmpty ? [] : safeFears
            )
            AppLogger.info("children.create.completed", [:])
            await fetchChildren(forceRefresh: true)
            newChildName = ""
            newChildAge = ""
            newChildAgeGroup = .sixToEight
            interests = []
            fears = []
            isLoading = false
            return true
        } catch {
            AppLogger.error("children.create.failed", [
                "error": String(describing: type(of: error))
            ])
            errorMessage = error.userFacingTurkishMessage
            isLoading = false
            return false
        }
    }

    /// Düzenleme moduna başlar: var olan çocuğun bilgilerini form alanlarına taşır.
    func beginEditing(child: ChildModel) {
        editingChild = child
        errorMessage = nil
        newChildName = child.name
        newChildAge = String(child.age)
        newChildAgeGroup = LumaAgeGroup.from(age: child.age)
        selectedEmoji = child.safeAvatarEmoji
        interests = child.interests ?? []
        fears = child.fears ?? []
        isEditSheetPresented = true
    }

    /// Var olan çocuğu günceller.
    func updateChild() async -> Bool {
        guard let baseChild = editingChild else { return false }
        let trimmedName = newChildName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Lütfen çocuğun adını gir."
            return false
        }

        isLoading = true
        errorMessage = nil

        let ageInt = suggestedAge(for: newChildAgeGroup)
        let safeInterests = Self.sanitizeTagList(interests)
        let safeFears = Self.sanitizeTagList(fears)
        do {
            AppLogger.info("children.update.request_sent", [
                "childId": baseChild.id.uuidString
            ])
            let updated = try await ChildrenAPIService.updateChild(
                id: baseChild.id,
                name: trimmedName,
                age: ageInt,
                profile: nil,
                avatarEmoji: ChildModel.sanitizeAvatarEmoji(selectedEmoji),
                interests: safeInterests,
                fears: safeFears
            )
            AppLogger.info("children.update.completed", [
                "childId": baseChild.id.uuidString
            ])

            interests = safeInterests
            fears = safeFears
            newChildName = trimmedName
            if let idx = children.firstIndex(where: { $0.id == updated.id }) {
                children[idx] = updated
            }
            if selectedChildForDetail?.id == updated.id {
                selectedChildForDetail = updated
            }

            await fetchChildren(forceRefresh: true)
            isLoading = false
            isEditSheetPresented = false
            editingChild = nil
            selectedEmoji = availableEmojis.first ?? ChildModel.defaultAvatarEmoji
            return true
        } catch {
            var logFields: [String: String] = [
                "childId": baseChild.id.uuidString,
                "payloadAge": "\(ageInt)",
                "interestsCount": "\(safeInterests.count)",
                "fearsCount": "\(safeFears.count)"
            ]
            logFields.merge(Self.logFieldsForChildUpdateError(error)) { _, new in new }
            AppLogger.error("children.update.failed", logFields)
            errorMessage = error.userFacingTurkishMessage
            isLoading = false
            return false
        }
    }

    /// Çocuk güncelleme hatalarında ayrıntı (konsol; sunucu `code` / `message` ve istemci vakaları).
    private static func logFieldsForChildUpdateError(_ error: Error) -> [String: String] {
        var f: [String: String] = [
            "errorType": String(describing: type(of: error)),
            "localizedDescription": error.localizedDescription
        ]
        if let api = error as? APIClientError {
            switch api {
            case .server(let code, let message):
                f["apiErrorCode"] = code
                f["apiErrorMessage"] = message
            case .networkFailure(let message):
                f["networkFailure"] = message
            case .unauthorized: f["clientError"] = "unauthorized"
            case .decodingFailed: f["clientError"] = "decodingFailed"
            case .invalidResponse: f["clientError"] = "invalidResponse"
            case .emptyData: f["clientError"] = "emptyData"
            case .invalidURL: f["clientError"] = "invalidURL"
            }
        }
        let ns = error as NSError
        f["nsDomain"] = ns.domain
        f["nsCode"] = "\(ns.code)"
        if let u = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            f["underlyingError"] = String(describing: u)
        }
        if let s = ns.userInfo[NSLocalizedDescriptionKey] as? String, !s.isEmpty {
            f["nsLocalizedDescription"] = s
        }
        return f
    }

    /// API `maxItems: 25` ve boş/çok uzun etiketlerden kaçınmak için.
    private static func sanitizeTagList(_ tags: [String]) -> [String] {
        tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(25)
            .map { String($0.prefix(200)) }
    }

    // MARK: - Age helpers

    private func suggestedAge(for group: LumaAgeGroup) -> Int {
        switch group {
        case .threeToFive:
            return 4
        case .sixToEight:
            return 7
        case .nineToEleven:
            return 10
        }
    }

    /// Çocuğu tamamen siler.
    func deleteChild(_ child: ChildModel) async -> Bool {
        isLoading = true
        do {
            try await ChildrenAPIService.deleteChild(id: child.id)

            await fetchChildren(forceRefresh: true)
            isLoading = false
            return true
        } catch {
            errorMessage = error.userFacingTurkishMessage
            isLoading = false
            return false
        }
    }
}
