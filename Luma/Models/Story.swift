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
    let audioUrl: String?
    let audioProvider: String?
    let audioModel: String?
    let audioVoiceId: String?
    let charactersUsed: Int?
    let narratedAt: String?
    let created_at: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case user_id = "user_id"
        case child_id = "child_id"
        case title, content, theme, age_group, language, cover_image_url, audio_url, created_at
        case audioUrl, audioProvider, audioModel, audioVoiceId, charactersUsed, narratedAt
        case audio_provider, audio_model, audio_voice_id, characters_used, narrated_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        user_id = try container.decode(UUID.self, forKey: .user_id)
        child_id = try container.decode(UUID.self, forKey: .child_id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        theme = try container.decode(String.self, forKey: .theme)
        age_group = try container.decodeIfPresent(String.self, forKey: .age_group)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        cover_image_url = try container.decodeIfPresent(String.self, forKey: .cover_image_url)
        audio_url = try container.decodeIfPresent(String.self, forKey: .audio_url)

        let audioUrlCamel = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        let audioUrlSnake = try container.decodeIfPresent(String.self, forKey: .audio_url)
        audioUrl = audioUrlCamel ?? audioUrlSnake

        let audioProviderCamel = try container.decodeIfPresent(String.self, forKey: .audioProvider)
        let audioProviderSnake = try container.decodeIfPresent(String.self, forKey: .audio_provider)
        audioProvider = audioProviderCamel ?? audioProviderSnake

        let audioModelCamel = try container.decodeIfPresent(String.self, forKey: .audioModel)
        let audioModelSnake = try container.decodeIfPresent(String.self, forKey: .audio_model)
        audioModel = audioModelCamel ?? audioModelSnake

        let audioVoiceIdCamel = try container.decodeIfPresent(String.self, forKey: .audioVoiceId)
        let audioVoiceIdSnake = try container.decodeIfPresent(String.self, forKey: .audio_voice_id)
        audioVoiceId = audioVoiceIdCamel ?? audioVoiceIdSnake

        let charactersUsedCamel = try container.decodeIfPresent(Int.self, forKey: .charactersUsed)
        let charactersUsedSnake = try container.decodeIfPresent(Int.self, forKey: .characters_used)
        charactersUsed = charactersUsedCamel ?? charactersUsedSnake

        let narratedAtCamel = try container.decodeIfPresent(String.self, forKey: .narratedAt)
        let narratedAtSnake = try container.decodeIfPresent(String.self, forKey: .narrated_at)
        narratedAt = narratedAtCamel ?? narratedAtSnake
        created_at = try container.decodeIfPresent(Date.self, forKey: .created_at)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(child_id, forKey: .child_id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(theme, forKey: .theme)
        try container.encodeIfPresent(age_group, forKey: .age_group)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(cover_image_url, forKey: .cover_image_url)
        try container.encodeIfPresent(audio_url, forKey: .audio_url)
        try container.encodeIfPresent(audioUrl, forKey: .audioUrl)
        try container.encodeIfPresent(audioProvider, forKey: .audioProvider)
        try container.encodeIfPresent(audioModel, forKey: .audioModel)
        try container.encodeIfPresent(audioVoiceId, forKey: .audioVoiceId)
        try container.encodeIfPresent(charactersUsed, forKey: .charactersUsed)
        try container.encodeIfPresent(narratedAt, forKey: .narratedAt)
        try container.encodeIfPresent(created_at, forKey: .created_at)
    }

    /// Üretim API’sinin minimal gövdesi; `user_id` vb. alanlar eksik olabilir (liste/detay tam kaydı getirir).
    internal init(
        id: UUID,
        userId: UUID,
        childId: UUID,
        title: String,
        content: String,
        theme: String,
        age_group: String? = nil,
        language: String? = nil,
        cover_image_url: String? = nil,
        audio_url: String? = nil,
        audioUrl: String? = nil,
        audioProvider: String? = nil,
        audioModel: String? = nil,
        audioVoiceId: String? = nil,
        charactersUsed: Int? = nil,
        narratedAt: String? = nil,
        created_at: Date? = nil
    ) {
        self.id = id
        self.user_id = userId
        self.child_id = childId
        self.title = title
        self.content = content
        self.theme = theme
        self.age_group = age_group
        self.language = language
        self.cover_image_url = cover_image_url
        self.audio_url = audio_url
        let resolvedURL = audioUrl ?? audio_url
        self.audioUrl = resolvedURL
        self.audioProvider = audioProvider
        self.audioModel = audioModel
        self.audioVoiceId = audioVoiceId
        self.charactersUsed = charactersUsed
        self.narratedAt = narratedAt
        self.created_at = created_at
    }

    /// `POST /v1/stories/generate` için `childId` / eksik `user_id` gibi alternatif anahtarlar.
    internal static func decodeFlexibleGeneratePayload(from decoder: Decoder) throws -> StoryModel {
        enum K: String, CodingKey {
            case id, title, content, theme, language
            case user_id
            case userId
            case child_id
            case childId
            case age_group
            case ageGroup
            case cover_image_url
            case coverImageUrl
            case audio_url
            case audioUrl
            case audioProvider
            case audio_provider
            case audioModel
            case audio_model
            case audioVoiceId
            case audio_voice_id
            case charactersUsed
            case characters_used
            case narratedAt
            case narrated_at
            case created_at
            case createdAt
        }

        let c = try decoder.container(keyedBy: K.self)
        let id = try c.decode(UUID.self, forKey: .id)
        let title = try c.decode(String.self, forKey: .title)
        let content = try c.decode(String.self, forKey: .content)
        let theme = try c.decode(String.self, forKey: .theme)

        let placeholderUser = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let userId = try c.decodeIfPresent(UUID.self, forKey: .user_id)
            ?? c.decodeIfPresent(UUID.self, forKey: .userId)
            ?? placeholderUser

        guard let childId = try c.decodeIfPresent(UUID.self, forKey: .child_id)
            ?? c.decodeIfPresent(UUID.self, forKey: .childId) else {
            throw DecodingError.dataCorruptedError(forKey: .child_id, in: c, debugDescription: "Missing child id")
        }

        let age_group = try c.decodeIfPresent(String.self, forKey: .age_group)
            ?? c.decodeIfPresent(String.self, forKey: .ageGroup)
        let language = try c.decodeIfPresent(String.self, forKey: .language)
        let cover_image_url = try c.decodeIfPresent(String.self, forKey: .cover_image_url)
            ?? c.decodeIfPresent(String.self, forKey: .coverImageUrl)

        let audioSnake = try c.decodeIfPresent(String.self, forKey: .audio_url)
        let audioCamel = try c.decodeIfPresent(String.self, forKey: .audioUrl)

        let audioProviderVal = try c.decodeIfPresent(String.self, forKey: .audioProvider)
            ?? c.decodeIfPresent(String.self, forKey: .audio_provider)
        let audioModelVal = try c.decodeIfPresent(String.self, forKey: .audioModel)
            ?? c.decodeIfPresent(String.self, forKey: .audio_model)
        let audioVoiceIdVal = try c.decodeIfPresent(String.self, forKey: .audioVoiceId)
            ?? c.decodeIfPresent(String.self, forKey: .audio_voice_id)

        let charactersUsedVal = try c.decodeIfPresent(Int.self, forKey: .charactersUsed)
            ?? c.decodeIfPresent(Int.self, forKey: .characters_used)

        let narratedAtVal = try c.decodeIfPresent(String.self, forKey: .narratedAt)
            ?? c.decodeIfPresent(String.self, forKey: .narrated_at)

        let created_at = try c.decodeIfPresent(Date.self, forKey: .created_at)
            ?? c.decodeIfPresent(Date.self, forKey: .createdAt)

        return StoryModel(
            id: id,
            userId: userId,
            childId: childId,
            title: title,
            content: content,
            theme: theme,
            age_group: age_group,
            language: language,
            cover_image_url: cover_image_url,
            audio_url: audioSnake,
            audioUrl: audioCamel ?? audioSnake,
            audioProvider: audioProviderVal,
            audioModel: audioModelVal,
            audioVoiceId: audioVoiceIdVal,
            charactersUsed: charactersUsedVal,
            narratedAt: narratedAtVal,
            created_at: created_at
        )
    }
}
