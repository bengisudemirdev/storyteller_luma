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

    let availableEmojis = ["🦊", "🦄", "🦁", "🐰", "🐼", "🦖", "🦋", "🐙", "🐵", "🐥"]
    private var lastChildrenFetchAt: Date?
    private let minChildrenFetchInterval: TimeInterval = 8
    private var isFetchingChildren = false

    func fetchChildren(forceRefresh: Bool = false) async {
        if isFetchingChildren { return }
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
                errorMessage = "Veriler alınırken bir hata oluştu: \(error.localizedDescription)"
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

        do {
            AppLogger.info("children.create.request_sent", [:])
            _ = try await ChildrenAPIService.createChild(
                name: newChildName,
                age: ageInt,
                profile: nil,
                avatarEmoji: ChildModel.sanitizeAvatarEmoji(selectedEmoji),
                interests: currentInterests.isEmpty ? [] : currentInterests,
                fears: currentFears.isEmpty ? [] : currentFears
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
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    /// Düzenleme moduna başlar: var olan çocuğun bilgilerini form alanlarına taşır.
    func beginEditing(child: ChildModel) {
        editingChild = child
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
        isLoading = true

        let ageInt = suggestedAge(for: newChildAgeGroup)
        do {
            AppLogger.info("children.update.request_sent", [
                "childId": baseChild.id.uuidString
            ])
            _ = try await ChildrenAPIService.updateChild(
                id: baseChild.id,
                name: newChildName,
                age: ageInt,
                profile: nil,
                avatarEmoji: ChildModel.sanitizeAvatarEmoji(selectedEmoji),
                interests: interests,
                fears: fears
            )
            AppLogger.info("children.update.completed", [
                "childId": baseChild.id.uuidString
            ])

            await fetchChildren(forceRefresh: true)
            isLoading = false
            isEditSheetPresented = false
            editingChild = nil
            selectedEmoji = availableEmojis.first ?? ChildModel.defaultAvatarEmoji
            return true
        } catch {
            AppLogger.error("children.update.failed", [
                "childId": baseChild.id.uuidString,
                "error": String(describing: type(of: error))
            ])
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
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
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
