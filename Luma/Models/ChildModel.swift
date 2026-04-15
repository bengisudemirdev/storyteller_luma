// Models/ChildModel.swift
import Foundation

struct ChildModel: Codable, Identifiable, Equatable {
    static let defaultAvatarEmoji = "🦊"

    let id: UUID
    /// Ebeveyn kullanıcı id (API: `user_id` veya `parent_id`)
    let parentId: UUID
    let name: String
    let age: Int
    let avatarEmoji: String
    let interests: [String]?
    let fears: [String]?
    let profile: String?
    
    var safeAvatarEmoji: String {
        Self.sanitizeAvatarEmoji(avatarEmoji)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case userId = "user_id"
        case name
        case age
        case avatarEmoji = "avatar_emoji"
        case interests
        case fears
        case profile
    }

    init(
        id: UUID,
        parentId: UUID,
        name: String,
        age: Int,
        avatarEmoji: String = ChildModel.defaultAvatarEmoji,
        interests: [String]? = nil,
        fears: [String]? = nil,
        profile: String? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.name = name
        self.age = age
        self.avatarEmoji = Self.sanitizeAvatarEmoji(avatarEmoji)
        self.interests = interests
        self.fears = fears
        self.profile = profile
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        if let p = try container.decodeIfPresent(UUID.self, forKey: .parentId) {
            self.parentId = p
        } else {
            self.parentId = try container.decode(UUID.self, forKey: .userId)
        }
        self.name = try container.decode(String.self, forKey: .name)
        if let intAge = try? container.decode(Int.self, forKey: .age) {
            self.age = intAge
        } else if let doubleAge = try? container.decode(Double.self, forKey: .age) {
            self.age = Int(doubleAge.rounded())
        } else {
            self.age = 7
        }
        self.avatarEmoji = Self.sanitizeAvatarEmoji(
            try container.decodeIfPresent(String.self, forKey: .avatarEmoji)
        )
        self.interests = Self.decodeOptionalStringArray(from: container, forKey: .interests)
        self.fears = Self.decodeOptionalStringArray(from: container, forKey: .fears)
        self.profile = try container.decodeIfPresent(String.self, forKey: .profile)
    }

    /// Sunucu `[]`, `null` veya nadiren farklı tipler döndürebilir; decode patlamasın.
    private static func decodeOptionalStringArray(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> [String]? {
        guard container.contains(key) else { return nil }
        if (try? container.decodeNil(forKey: key)) == true { return nil }
        if let arr = try? container.decode([String].self, forKey: key) { return arr }
        return []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(parentId, forKey: .parentId)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(Self.sanitizeAvatarEmoji(avatarEmoji), forKey: .avatarEmoji)
        try container.encodeIfPresent(interests, forKey: .interests)
        try container.encodeIfPresent(fears, forKey: .fears)
        try container.encodeIfPresent(profile, forKey: .profile)
    }

    static func == (lhs: ChildModel, rhs: ChildModel) -> Bool {
        lhs.id == rhs.id
    }

    static func sanitizeAvatarEmoji(_ rawValue: String?) -> String {
        guard let rawValue else { return defaultAvatarEmoji }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return defaultAvatarEmoji }
        if trimmed == "?" || trimmed.contains("\u{FFFD}") { return defaultAvatarEmoji }

        guard let firstCharacter = trimmed.first else { return defaultAvatarEmoji }
        let glyph = String(firstCharacter)
        if glyph.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
            return glyph
        }
        return defaultAvatarEmoji
    }
}
