import Foundation


struct StoryModel: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let child_id: UUID
    let title: String
    let content: String
    let theme: String
    let age_group: String?
    let language: String?
    let cover_image_url: String?
    let audio_url: String?
    let created_at: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case user_id = "user_id"
        case child_id = "child_id"
        case title, content, theme, age_group, language, cover_image_url, audio_url, created_at
    }
}
