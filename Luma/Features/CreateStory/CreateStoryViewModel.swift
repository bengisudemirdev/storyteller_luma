import Foundation
import Combine

@MainActor
class CreateStoryViewModel: ObservableObject {
    enum PendingAction {
        case createStory
    }

    @Published var childName: String = ""
    @Published var interest: String = ""
    @Published var selectedTheme: String = "Macera"
    @Published var selectedInterests: [String] = []
    @Published var isLoading: Bool = false
    @Published var showReaderView: Bool = false
    @Published var generatedStory: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showCreditStore: Bool = false
    @Published var children: [ChildModel] = []
    @Published var selectedChild: ChildModel? = nil
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var generatedStoryModel: StoryModel? = nil
    @Published var pendingAction: PendingAction?
    private var hasLoadedChildrenOnce = false
    private var generationTask: Task<Void, Never>?

    func createStory() {
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        isLoading = true

        AppLogger.info("stories.create.tapped", [
            "hasSelectedChild": selectedChild != nil ? "true" : "false",
            "theme": mapThemeToBackend(selectedTheme),
            "selectedInterestsCount": "\(selectedInterests.count)",
            "hasExtraContext": interest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "false" : "true"
        ])

        generationTask?.cancel()
        generationTask = Task {
            let entitlementsFresh = await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
            // Hak bilgisi yüklenemediyse (ağ/yenileme sorunu) eski ya da boş bilgiyle kullanıcıyı engelleme: karar sunucuda
            // verilir (`STORY_LIMIT_REACHED` aşağıda paywall/mesaj olarak ele alınır). Yalnızca taze ve kesin "0 hak" engeller.
            guard !entitlementsFresh || EntitlementStore.shared.canCreateStory else {
                if EntitlementStore.shared.hasPremiumAccess {
                    errorMessage = "Bu ay için kişiselleştirilmiş masal hakkın doldu."
                    showErrorAlert = true
                } else {
                    showCreditStore = true
                    pendingAction = .createStory
                }
                isLoading = false
                return
            }

            do {
                // Profil seçilmediyse sunucu `childName` ile profilsiz (child_id = NULL) masal üretir;
                // eskiden geçici profil açılıp silinirken cascade masalı da siliyordu.
                let childId: UUID? = selectedChild?.id

                let backendTheme = mapThemeToBackend(selectedTheme)
                let extra = interest.trimmingCharacters(in: .whitespacesAndNewlines)
                let extraContext = extra.isEmpty ? nil : extra
                let perStoryInterests = selectedInterests.isEmpty ? nil : selectedInterests

                let story = try await StoryService.generateStory(
                    childId: childId,
                    childName: trimmedName,
                    childAge: nil,
                    theme: backendTheme,
                    language: "Türkçe",
                    extraContext: extraContext,
                    selectedInterests: perStoryInterests,
                    storyGoal: nil
                )

                generatedStoryModel = story
                generatedStory = story.content
                showReaderView = true
                await EntitlementStore.shared.refreshFromBackend()
                await SubscriptionManager.shared.refreshPlanFromServer()
                await CreditBalanceViewModel.shared.refreshBalance()
                NotificationCenter.default.post(name: .lumaSavedStoriesDidChange, object: nil)
            } catch {
                if Task.isCancelled || error is CancellationError {
                    // Kullanıcı beklemekten vazgeçti; hata gösterme. Sunucu masalı tamamlarsa kayıtlı masallarda görünür.
                    isLoading = false
                    return
                }
                // Model: aylık kota. Hak dolduysa Premium kullanıcıya bilgi, ücretsiz kullanıcıya paywall gösterilir.
                if let apiError = error as? APIClientError,
                   apiError.serverErrorCode == "STORY_LIMIT_REACHED" || apiError.isInsufficientCredits {
                    if PortfolioAccessMode.isEnabled || EntitlementStore.shared.hasPremiumAccess {
                        errorMessage = "Bu ay için kişiselleştirilmiş masal hakkın doldu."
                        showErrorAlert = true
                    } else {
                        showCreditStore = true
                        pendingAction = .createStory
                        showErrorAlert = false
                    }
                    isLoading = false
                    return
                }
                errorMessage = Self.userFacingStoryCreationFailureMessage(for: error)
                showErrorAlert = true
                AppLogger.error("stories.create.failed", [
                    "childId": selectedChild?.id.uuidString ?? "ad_hoc",
                    "theme": mapThemeToBackend(selectedTheme),
                    "error": String(describing: type(of: error))
                ])
            }
            isLoading = false
        }
    }

    /// Üretim beklemesini bırakır (yükleme ekranındaki "Beklemek istemiyorum").
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isLoading = false
        // Sunucu isteği tamamlayabilir; liste sonradan yenilensin.
        Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            NotificationCenter.default.post(name: .lumaSavedStoriesDidChange, object: nil)
        }
    }

    func fetchChildren(forceRefresh: Bool = false) async {
        if hasLoadedChildrenOnce && !forceRefresh {
            return
        }
        AppLogger.info("children.fetch.started", [:])
        // NOT: `isLoading` masal üretimi için tam ekran "Masalın hazırlanıyor" katmanını açar; çocuk listesi
        // yüklenirken bu katman çıkmamalı (ağ yavaşken ekran donmuş gibi görünüyordu).
        do {
            let fetched = try await ChildrenAPIService.fetchChildren()
            children = fetched
            hasLoadedChildrenOnce = true
            AppLogger.info("children.fetch.completed", [
                "count": "\(fetched.count)"
            ])
        } catch {
            AppLogger.error("children.fetch.failed", [
                "error": String(describing: type(of: error))
            ])
        }
    }

    func saveStoryToParent(childId: UUID, title: String, content: String, theme: String) async -> Bool {
        _ = (childId, title, content, theme)
        saveSuccess = true
        return true
    }

    /// Kurtarma sonrası bile hata varsa teknik ayrıntı göstermeden sabit mesaj; iş kuralı hatalarında sunucunun Türkçe eşlemesi.
    private static func userFacingStoryCreationFailureMessage(for error: Error) -> String {
        let generic = "Masal oluşturulurken bir sorun oluştu. Lütfen tekrar deneyin."
        guard let api = error as? APIClientError else { return generic }
        switch api {
        case .server:
            return api.errorDescription ?? generic
        case .unauthorized:
            return generic
        case .paymentRequired:
            return api.errorDescription ?? generic
        case .decodingFailed, .networkFailure, .invalidResponse, .emptyData, .invalidURL:
            return generic
        }
    }

    /// Arayüzdeki tema adı → backend tema allowlist'i (`themeWhitelist.ts`). Her tema kendi hedef/ton ayarına sahiptir.
    private func mapThemeToBackend(_ theme: String) -> String {
        switch theme.lowercased() {
        case "uyku":
            return "uyku"
        case "dostluk":
            return "dostluk"
        case "eğitici":
            return "eğitici"
        case "macera":
            return "macera"
        default:
            // Bilinmeyen tema: en güvenli/sakin varsayılan.
            return "uyku"
        }
    }

    func handlePurchaseCompletion() {
        Task { @MainActor in
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
            guard let action = pendingAction else { return }
            pendingAction = nil
            switch action {
            case .createStory:
                createStory()
            }
        }
    }
}
