import Foundation

struct AuthMeDataDTO: Decodable {
    let user: AuthMeUserDTO
}

struct AuthMeUserDTO: Decodable {
    let id: UUID
    let email: String?

    /// Aşağıdakiler backend genişlemesi — opsiyonel; entitlement fallback için kullanılır.
    let subscriptionPlan: String?
    let subscriptionStatus: String?
    let productId: String?
    let currentPeriodStart: String?
    let currentPeriodEnd: String?
    let storyLimitMonthly: Int?
    let storyUsedThisMonth: Int?
    let storyRemainingThisMonth: Int?
    let voiceLimitMonthly: Int?
    let voiceUsedThisMonth: Int?
    let voiceRemainingThisMonth: Int?
    let extraVoiceCredits: Int?
    let childProfileLimit: Int?
    let isPremium: Bool?
    let isFamily: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case subscriptionPlan
        case subscription_plan
        case subscriptionStatus
        case subscription_status
        case productId
        case product_id
        case currentPeriodStart
        case current_period_start
        case currentPeriodEnd
        case current_period_end
        case storyLimitMonthly
        case story_limit_monthly
        case storyUsedThisMonth
        case story_used_this_month
        case storyRemainingThisMonth
        case story_remaining_this_month
        case voiceLimitMonthly
        case voice_limit_monthly
        case voiceUsedThisMonth
        case voice_used_this_month
        case voiceRemainingThisMonth
        case voice_remaining_this_month
        case extraVoiceCredits
        case extra_voice_credits
        case childProfileLimit
        case child_profile_limit
        case isPremium
        case is_premium
        case isFamily
        case is_family
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        email = try c.decodeIfPresent(String.self, forKey: .email)

        subscriptionPlan = try c.decodeIfPresent(String.self, forKey: .subscriptionPlan)
            ?? c.decodeIfPresent(String.self, forKey: .subscription_plan)
        subscriptionStatus = try c.decodeIfPresent(String.self, forKey: .subscriptionStatus)
            ?? c.decodeIfPresent(String.self, forKey: .subscription_status)
        productId = try c.decodeIfPresent(String.self, forKey: .productId)
            ?? c.decodeIfPresent(String.self, forKey: .product_id)
        currentPeriodStart = try c.decodeIfPresent(String.self, forKey: .currentPeriodStart)
            ?? c.decodeIfPresent(String.self, forKey: .current_period_start)
        currentPeriodEnd = try c.decodeIfPresent(String.self, forKey: .currentPeriodEnd)
            ?? c.decodeIfPresent(String.self, forKey: .current_period_end)

        storyLimitMonthly = c.decodeFlexibleInt(forKey: .storyLimitMonthly)
            ?? c.decodeFlexibleInt(forKey: .story_limit_monthly)
        storyUsedThisMonth = c.decodeFlexibleInt(forKey: .storyUsedThisMonth)
            ?? c.decodeFlexibleInt(forKey: .story_used_this_month)
        storyRemainingThisMonth = c.decodeFlexibleInt(forKey: .storyRemainingThisMonth)
            ?? c.decodeFlexibleInt(forKey: .story_remaining_this_month)
        voiceLimitMonthly = c.decodeFlexibleInt(forKey: .voiceLimitMonthly)
            ?? c.decodeFlexibleInt(forKey: .voice_limit_monthly)
        voiceUsedThisMonth = c.decodeFlexibleInt(forKey: .voiceUsedThisMonth)
            ?? c.decodeFlexibleInt(forKey: .voice_used_this_month)
        voiceRemainingThisMonth = c.decodeFlexibleInt(forKey: .voiceRemainingThisMonth)
            ?? c.decodeFlexibleInt(forKey: .voice_remaining_this_month)
        extraVoiceCredits = c.decodeFlexibleInt(forKey: .extraVoiceCredits)
            ?? c.decodeFlexibleInt(forKey: .extra_voice_credits)
        childProfileLimit = c.decodeFlexibleInt(forKey: .childProfileLimit)
            ?? c.decodeFlexibleInt(forKey: .child_profile_limit)

        if let b = c.decodeFlexibleBool(forKey: .isPremium) {
            isPremium = b
        } else if let b = c.decodeFlexibleBool(forKey: .is_premium) {
            isPremium = b
        } else {
            isPremium = nil
        }

        if let b = c.decodeFlexibleBool(forKey: .isFamily) {
            isFamily = b
        } else if let b = c.decodeFlexibleBool(forKey: .is_family) {
            isFamily = b
        } else {
            isFamily = nil
        }
    }

    func asEntitlementSnapshot() -> UserEntitlementSnapshot {
        UserEntitlementSnapshot(
            subscriptionPlan: subscriptionPlan,
            subscriptionStatus: subscriptionStatus,
            productId: productId,
            currentPeriodStart: currentPeriodStart,
            currentPeriodEnd: currentPeriodEnd,
            storyLimitMonthly: storyLimitMonthly,
            storyUsedThisMonth: storyUsedThisMonth,
            storyRemainingThisMonth: storyRemainingThisMonth,
            voiceLimitMonthly: voiceLimitMonthly,
            voiceUsedThisMonth: voiceUsedThisMonth,
            voiceRemainingThisMonth: voiceRemainingThisMonth,
            extraVoiceCredits: extraVoiceCredits,
            childProfileLimit: childProfileLimit,
            isPremium: isPremium,
            isFamily: isFamily
        )
    }
}

struct AuthDeleteMeDataDTO: Decodable {
    let message: String?
}

enum AuthAPIService {
    private static let syncCoordinator = AuthMeSyncCoordinator()

    static func syncCurrentUser(force: Bool = false) async throws -> AuthMeUserDTO {
        try await syncCoordinator.sync(force: force)
    }

    /// `POST /v1/auth/forgot-password` — sunucu Supabase `resetPasswordForEmail` çağırır; yanıt her zaman 200 (enumerasyon yok).
    static func sendForgotPassword(email: String) async throws -> String {
        let endpoint = APIEndpoint(path: "/v1/auth/forgot-password", method: .post)
        let data: ForgotPasswordMessageDTO = try await APIClient.shared.requestWithoutAuthentication(
            endpoint,
            body: ForgotPasswordEmailBody(email: email)
        )
        let trimmed = data.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }
        return "Bu e-posta için bir hesap varsa, kısa süre içinde sıfırlama talimatları gönderilir."
    }

    /// `DELETE /v1/auth/me` — giriş yapmış kullanıcının hesabını backend üzerinden siler.
    static func deleteCurrentUserAccount() async throws -> String {
        let endpoint = APIEndpoint(path: "/v1/auth/me", method: .delete)
        let data: AuthDeleteMeDataDTO = try await APIClient.shared.request(endpoint)
        return data.message?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (data.message ?? "Hesabınız silindi.")
            : "Hesabınız silindi."
    }
}

private struct ForgotPasswordEmailBody: Encodable {
    let email: String
}

private struct ForgotPasswordMessageDTO: Decodable {
    let message: String?
}

private enum AuthMeSyncError: LocalizedError {
    case throttled

    var errorDescription: String? {
        switch self {
        case .throttled:
            return "Kullanıcı eşitlemesi kısa süreliğine ertelendi."
        }
    }
}

private actor AuthMeSyncCoordinator {
    private var cachedUser: AuthMeUserDTO?
    private var lastSyncedAt: Date?
    private var lastAttemptAt: Date?
    private var inFlightTask: Task<AuthMeUserDTO, Error>?
    private let cooldown: TimeInterval = 60
    private let retryBackoffAfterFailure: TimeInterval = 20

    func sync(force: Bool) async throws -> AuthMeUserDTO {
        if let inFlightTask {
            return try await inFlightTask.value
        }

        if !force,
           let cachedUser,
           let lastSyncedAt,
           Date().timeIntervalSince(lastSyncedAt) < cooldown {
            return cachedUser
        }

        if !force,
           let lastAttemptAt,
           Date().timeIntervalSince(lastAttemptAt) < retryBackoffAfterFailure {
            if let cachedUser {
                return cachedUser
            }
            throw AuthMeSyncError.throttled
        }

        lastAttemptAt = Date()
        let task = Task<AuthMeUserDTO, Error> {
            let endpoint = APIEndpoint(path: "/v1/auth/me", method: .post)
            let data: AuthMeDataDTO = try await APIClient.shared.request(endpoint)
            return data.user
        }
        inFlightTask = task

        do {
            let user = try await task.value
            cachedUser = user
            lastSyncedAt = Date()
            inFlightTask = nil
            return user
        } catch {
            inFlightTask = nil
            throw error
        }
    }
}

