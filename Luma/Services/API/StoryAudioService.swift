import Foundation

struct NarrationResponse: Decodable {
    let audioUrl: String
    let audioProvider: String?
    let audioModel: String?
    let audioVoiceId: String?
    let charactersUsed: Int?
}

enum StoryAudioServiceError: LocalizedError {
    case insufficientCredits
    case unauthorized
    case storyNotFound
    case failed

    var errorDescription: String? {
        switch self {
        case .insufficientCredits:
            return "Seslendirme için yeterli kredin yok."
        case .unauthorized:
            return "Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap."
        case .storyNotFound:
            return "Masal bulunamadı. Lütfen tekrar deneyin."
        case .failed:
            return "Masal seslendirilirken bir hata oluştu."
        }
    }
}

enum StoryAudioService {
    /// Gerçek uç nokta `StoryService.narrateStory` → `POST /v1/stories/{id}/narrate` (kişisel masal; klasik masal ayrıdır).
    static func narrateStory(storyId: String) async throws -> NarrationResponse {
        guard let id = UUID(uuidString: storyId) else {
            throw StoryAudioServiceError.failed
        }
        return try await StoryService.narrateStory(id: id)
    }
}
