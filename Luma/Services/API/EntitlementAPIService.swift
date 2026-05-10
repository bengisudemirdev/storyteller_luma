import Foundation

/// `GET /v1/me/entitlements` gövdesi (`APIClient` zarfından sonra `data`).
private struct MeEntitlementsPayloadDTO: Decodable {
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
        case subscriptionPlan
        case subscriptionStatus
        case productId
        case currentPeriodStart
        case currentPeriodEnd
        case storyLimitMonthly
        case storyUsedThisMonth
        case storyRemainingThisMonth
        case voiceLimitMonthly
        case voiceUsedThisMonth
        case voiceRemainingThisMonth
        case extraVoiceCredits
        case childProfileLimit
        case isPremium
        case isFamily
        case entitlements
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        var subscriptionPlan = try c.decodeIfPresent(String.self, forKey: .subscriptionPlan)
        var subscriptionStatus = try c.decodeIfPresent(String.self, forKey: .subscriptionStatus)
        var productId = try c.decodeIfPresent(String.self, forKey: .productId)
        var currentPeriodStart = try c.decodeIfPresent(String.self, forKey: .currentPeriodStart)
        var currentPeriodEnd = try c.decodeIfPresent(String.self, forKey: .currentPeriodEnd)
        var storyLimitMonthly = c.decodeFlexibleInt(forKey: .storyLimitMonthly)
        var storyUsedThisMonth = c.decodeFlexibleInt(forKey: .storyUsedThisMonth)
        var storyRemainingThisMonth = c.decodeFlexibleInt(forKey: .storyRemainingThisMonth)
        var voiceLimitMonthly = c.decodeFlexibleInt(forKey: .voiceLimitMonthly)
        var voiceUsedThisMonth = c.decodeFlexibleInt(forKey: .voiceUsedThisMonth)
        var voiceRemainingThisMonth = c.decodeFlexibleInt(forKey: .voiceRemainingThisMonth)
        var extraVoiceCredits = c.decodeFlexibleInt(forKey: .extraVoiceCredits)
        var childProfileLimit = c.decodeFlexibleInt(forKey: .childProfileLimit)
        var isPremium = c.decodeFlexibleBool(forKey: .isPremium)
        var isFamily = c.decodeFlexibleBool(forKey: .isFamily)

        if let nested = try c.decodeIfPresent(NestedEntitlements.self, forKey: .entitlements) {
            subscriptionPlan = subscriptionPlan ?? nested.subscriptionPlan
            subscriptionStatus = subscriptionStatus ?? nested.subscriptionStatus
            productId = productId ?? nested.productId
            currentPeriodStart = currentPeriodStart ?? nested.currentPeriodStart
            currentPeriodEnd = currentPeriodEnd ?? nested.currentPeriodEnd
            storyLimitMonthly = storyLimitMonthly ?? nested.storyLimitMonthly
            storyUsedThisMonth = storyUsedThisMonth ?? nested.storyUsedThisMonth
            storyRemainingThisMonth = storyRemainingThisMonth ?? nested.storyRemainingThisMonth
            voiceLimitMonthly = voiceLimitMonthly ?? nested.voiceLimitMonthly
            voiceUsedThisMonth = voiceUsedThisMonth ?? nested.voiceUsedThisMonth
            voiceRemainingThisMonth = voiceRemainingThisMonth ?? nested.voiceRemainingThisMonth
            extraVoiceCredits = extraVoiceCredits ?? nested.extraVoiceCredits
            childProfileLimit = childProfileLimit ?? nested.childProfileLimit
            if isPremium == nil { isPremium = nested.isPremium }
            if isFamily == nil { isFamily = nested.isFamily }
        }

        self.init(
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

    private init(
        subscriptionPlan: String?,
        subscriptionStatus: String?,
        productId: String?,
        currentPeriodStart: String?,
        currentPeriodEnd: String?,
        storyLimitMonthly: Int?,
        storyUsedThisMonth: Int?,
        storyRemainingThisMonth: Int?,
        voiceLimitMonthly: Int?,
        voiceUsedThisMonth: Int?,
        voiceRemainingThisMonth: Int?,
        extraVoiceCredits: Int?,
        childProfileLimit: Int?,
        isPremium: Bool?,
        isFamily: Bool?
    ) {
        self.subscriptionPlan = subscriptionPlan
        self.subscriptionStatus = subscriptionStatus
        self.productId = productId
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
        self.storyLimitMonthly = storyLimitMonthly
        self.storyUsedThisMonth = storyUsedThisMonth
        self.storyRemainingThisMonth = storyRemainingThisMonth
        self.voiceLimitMonthly = voiceLimitMonthly
        self.voiceUsedThisMonth = voiceUsedThisMonth
        self.voiceRemainingThisMonth = voiceRemainingThisMonth
        self.extraVoiceCredits = extraVoiceCredits
        self.childProfileLimit = childProfileLimit
        self.isPremium = isPremium
        self.isFamily = isFamily
    }

    /// `data.entitlements { ... }` şekli.
    private struct NestedEntitlements: Decodable {
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
            case subscriptionPlan
            case subscriptionStatus
            case productId
            case currentPeriodStart
            case currentPeriodEnd
            case storyLimitMonthly
            case storyUsedThisMonth
            case storyRemainingThisMonth
            case voiceLimitMonthly
            case voiceUsedThisMonth
            case voiceRemainingThisMonth
            case extraVoiceCredits
            case childProfileLimit
            case isPremium
            case isFamily
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            subscriptionPlan = try c.decodeIfPresent(String.self, forKey: .subscriptionPlan)
            subscriptionStatus = try c.decodeIfPresent(String.self, forKey: .subscriptionStatus)
            productId = try c.decodeIfPresent(String.self, forKey: .productId)
            currentPeriodStart = try c.decodeIfPresent(String.self, forKey: .currentPeriodStart)
            currentPeriodEnd = try c.decodeIfPresent(String.self, forKey: .currentPeriodEnd)
            storyLimitMonthly = c.decodeFlexibleInt(forKey: .storyLimitMonthly)
            storyUsedThisMonth = c.decodeFlexibleInt(forKey: .storyUsedThisMonth)
            storyRemainingThisMonth = c.decodeFlexibleInt(forKey: .storyRemainingThisMonth)
            voiceLimitMonthly = c.decodeFlexibleInt(forKey: .voiceLimitMonthly)
            voiceUsedThisMonth = c.decodeFlexibleInt(forKey: .voiceUsedThisMonth)
            voiceRemainingThisMonth = c.decodeFlexibleInt(forKey: .voiceRemainingThisMonth)
            extraVoiceCredits = c.decodeFlexibleInt(forKey: .extraVoiceCredits)
            childProfileLimit = c.decodeFlexibleInt(forKey: .childProfileLimit)
            isPremium = c.decodeFlexibleBool(forKey: .isPremium)
            isFamily = c.decodeFlexibleBool(forKey: .isFamily)
        }
    }

    func asSnapshot() -> UserEntitlementSnapshot {
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

enum EntitlementAPIService {
    /// Önce `GET /v1/me/entitlements`; başarısız olursa `POST /v1/auth/me` kullanıcı nesnesindeki alanlar.
    static func fetchEntitlements() async throws -> UserEntitlementSnapshot {
        do {
            let endpoint = APIEndpoint(path: "/v1/me/entitlements", method: .get)
            let dto: MeEntitlementsPayloadDTO = try await APIClient.shared.request(endpoint)
            return dto.asSnapshot()
        } catch {
            let user = try await AuthAPIService.syncCurrentUser(force: true)
            return user.asEntitlementSnapshot()
        }
    }
}
