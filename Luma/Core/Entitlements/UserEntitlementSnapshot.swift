import Foundation

/// Backend `GET /v1/me/entitlements` veya `auth/me` içindeki entitlement alanları — tek kaynak.
struct UserEntitlementSnapshot: Codable, Equatable, Sendable {
    var subscriptionPlan: String?
    var subscriptionStatus: String?
    var productId: String?
    var currentPeriodStart: String?
    var currentPeriodEnd: String?
    var storyLimitMonthly: Int?
    var storyUsedThisMonth: Int?
    var storyRemainingThisMonth: Int?
    var voiceLimitMonthly: Int?
    var voiceUsedThisMonth: Int?
    var voiceRemainingThisMonth: Int?
    var extraVoiceCredits: Int?
    var childProfileLimit: Int?
    var isPremium: Bool?
    var isFamily: Bool?
}

// MARK: - Esnek decode yardımcıları

extension KeyedDecodingContainer where K: CodingKey {
    func decodeFlexibleInt(forKey key: K) -> Int? {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
        if let s = try? decode(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    func decodeFlexibleBool(forKey key: K) -> Bool? {
        if let v = try? decode(Bool.self, forKey: key) { return v }
        if let i = decodeFlexibleInt(forKey: key) { return i != 0 }
        return nil
    }
}
