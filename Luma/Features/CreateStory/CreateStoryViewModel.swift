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
    let storyCreditCost: Int = CreditCost.story

    func createStory() {
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        if !CreditBalanceViewModel.shared.hasCredits(required: storyCreditCost) {
            errorMessage = "Bu işlem için en az \(storyCreditCost) kredi gerekiyor."
            showCreditStore = true
            pendingAction = .createStory
            return
        }
        isLoading = true

        AppLogger.info("stories.create.tapped", [
            "hasSelectedChild": selectedChild != nil ? "true" : "false",
            "theme": mapThemeToBackend(selectedTheme),
            "selectedInterestsCount": "\(selectedInterests.count)",
            "hasExtraContext": interest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "false" : "true"
        ])

        Task {
            var ephemeralChildId: UUID?
            do {
                let childId: UUID
                if let existing = selectedChild {
                    childId = existing.id
                } else {
                    // Üretim API’si childId istiyor; kalıcı profil istenmiyorsa geçici kayıt açılıp masal sonrası silinir.
                    let newChild = try await ChildrenAPIService.createChild(
                        name: trimmedName,
                        age: 7,
                        profile: nil,
                        avatarEmoji: ChildModel.defaultAvatarEmoji,
                        interests: nil,
                        fears: nil
                    )
                    childId = newChild.id
                    ephemeralChildId = newChild.id
                }

                let backendTheme = mapThemeToBackend(selectedTheme)
                let extra = interest.trimmingCharacters(in: .whitespacesAndNewlines)
                let extraContext = extra.isEmpty ? nil : extra
                let perStoryInterests = selectedInterests.isEmpty ? nil : selectedInterests

                let story = try await StoryService.generateStory(
                    childId: childId,
                    theme: backendTheme,
                    language: "Türkçe",
                    extraContext: extraContext,
                    selectedInterests: perStoryInterests,
                    storyGoal: nil
                )

                if let tempId = ephemeralChildId {
                    do {
                        try await ChildrenAPIService.deleteChild(id: tempId)
                    } catch {
                        AppLogger.error("children.delete.ephemeral_failed", [
                            "childId": tempId.uuidString,
                            "error": String(describing: type(of: error))
                        ])
                    }
                }

                generatedStoryModel = story
                generatedStory = story.content
                showReaderView = true
                await CreditBalanceViewModel.shared.refreshBalance()
            } catch {
                if let apiError = error as? APIClientError, apiError.isInsufficientCredits {
                    errorMessage = "Bu işlem için en az \(storyCreditCost) kredi gerekiyor."
                    showCreditStore = true
                    pendingAction = .createStory
                    showErrorAlert = false
                    isLoading = false
                    return
                }
                if let tempId = ephemeralChildId {
                    do {
                        try await ChildrenAPIService.deleteChild(id: tempId)
                    } catch {
                        AppLogger.error("children.delete.ephemeral_failed", [
                            "childId": tempId.uuidString,
                            "error": String(describing: type(of: error))
                        ])
                    }
                }
                errorMessage = error.userFacingTurkishMessage
                showErrorAlert = true
                AppLogger.error("stories.create.failed", [
                    "childId": selectedChild?.id.uuidString ?? ephemeralChildId?.uuidString ?? "none",
                    "theme": mapThemeToBackend(selectedTheme),
                    "error": String(describing: type(of: error))
                ])
            }
            isLoading = false
        }
    }

    func fetchChildren(forceRefresh: Bool = false) async {
        if hasLoadedChildrenOnce && !forceRefresh {
            return
        }
        AppLogger.info("children.fetch.started", [:])
        isLoading = true
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
        isLoading = false
    }

    func saveStoryToParent(childId: UUID, title: String, content: String, theme: String) async -> Bool {
        _ = (childId, title, content, theme)
        saveSuccess = true
        return true
    }

    private func mapThemeToBackend(_ theme: String) -> String {
        switch theme.lowercased() {
        case "uyku":
            return "hayvanlar"
        case "dostluk":
            return "arkadaşlık"
        case "eğitici":
            return "umut"
        case "macera":
            return "adventure"
        default:
            return "hayvanlar"
        }
    }

    func handlePurchaseCompletion() {
        guard let pendingAction else { return }
        self.pendingAction = nil
        switch pendingAction {
        case .createStory:
            createStory()
        }
    }
}
