import Foundation
import Combine

@MainActor
class CreateStoryViewModel: ObservableObject {
    @Published var childName: String = ""
    @Published var interest: String = ""
    @Published var selectedTheme: String = "Macera"
    @Published var selectedInterests: [String] = []
    @Published var isLoading: Bool = false
    @Published var showReaderView: Bool = false
    @Published var generatedStory: String = ""
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String? = nil
    @Published var children: [ChildModel] = []
    @Published var selectedChild: ChildModel? = nil
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var generatedStoryModel: StoryModel? = nil

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

        Task {
            do {
                let childId: UUID
                if let existing = selectedChild {
                    childId = existing.id
                } else {
                    let newChild = try await ChildrenAPIService.createChild(
                        name: trimmedName,
                        age: nil,
                        profile: nil,
                        avatarEmoji: nil,
                        interests: nil,
                        fears: nil
                    )
                    childId = newChild.id
                    if !children.contains(where: { $0.id == newChild.id }) {
                        children.append(newChild)
                    }
                    selectedChild = newChild
                    childName = newChild.name
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
                generatedStoryModel = story
                generatedStory = story.content
                showReaderView = true
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
                AppLogger.error("stories.create.failed", [
                    "childId": selectedChild?.id.uuidString ?? "none",
                    "theme": mapThemeToBackend(selectedTheme),
                    "error": String(describing: type(of: error))
                ])
            }
            isLoading = false
        }
    }

    func fetchChildren() async {
        AppLogger.info("children.fetch.started", [:])
        isLoading = true
        do {
            let fetched = try await ChildrenAPIService.fetchChildren()
            children = fetched
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
}
