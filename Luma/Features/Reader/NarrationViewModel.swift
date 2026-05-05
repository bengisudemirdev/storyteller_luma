import Foundation
import Combine

@MainActor
final class NarrationViewModel: ObservableObject {
    struct Request {
        let text: String
        let displayTitle: String
        let classicTaleCacheId: String?
        let storyId: UUID?
        let storyAudioURL: String?
    }

    @Published var showCreditStore = false
    @Published var infoMessage: String?
    private(set) var pendingRequest: Request?

    func toggleOrStart(with request: Request, playback: NarrationPlaybackCenter) {
        let isClassicTaleNarration = request.classicTaleCacheId != nil

        if !isClassicTaleNarration,
           !playback.isSameSession(text: request.text, classicTaleCacheId: request.classicTaleCacheId, storyId: request.storyId),
           !CreditBalanceViewModel.shared.hasCredits(required: CreditCost.narration) {
            infoMessage = "Seslendirme için en az \(CreditCost.narration) kredi gerekir."
            pendingRequest = request
            showCreditStore = true
            return
        }

        playback.toggleOrStart(
            text: request.text,
            displayTitle: request.displayTitle,
            classicTaleCacheId: request.classicTaleCacheId,
            storyId: request.storyId,
            storyAudioURL: request.storyAudioURL
        )
    }

    func handlePurchaseCompletion(playback: NarrationPlaybackCenter) {
        guard let pendingRequest else { return }
        self.pendingRequest = nil
        toggleOrStart(with: pendingRequest, playback: playback)
    }
}
