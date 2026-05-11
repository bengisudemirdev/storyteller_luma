import Foundation
import Combine

/// Backend entitlement durumu — tek kaynak; kalıcı önbellek yalnızca son başarılı fetch için bootstrap.
@MainActor
final class EntitlementStore: ObservableObject {
    static let shared = EntitlementStore()

    private static let persistenceKey = "luma_user_entitlements_snapshot_v1"

    @Published private(set) var subscriptionPlan: String?
    @Published private(set) var subscriptionStatus: String?
    @Published private(set) var productId: String?
    @Published private(set) var currentPeriodStart: String?
    @Published private(set) var currentPeriodEnd: String?
    @Published private(set) var storyLimitMonthly: Int?
    @Published private(set) var storyUsedThisMonth: Int?
    @Published private(set) var storyRemainingThisMonth: Int?
    @Published private(set) var voiceLimitMonthly: Int?
    @Published private(set) var voiceUsedThisMonth: Int?
    @Published private(set) var voiceRemainingThisMonth: Int?
    @Published private(set) var extraVoiceCredits: Int?
    @Published private(set) var childProfileLimit: Int?
    @Published private(set) var isPremiumFlag: Bool?
    @Published private(set) var isFamilyFlag: Bool?

    @Published private(set) var lastSuccessfulFetchAt: Date?
    @Published private(set) var lastFetchErrorDescription: String?

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.persistenceKey),
           let snap = try? JSONDecoder().decode(UserEntitlementSnapshot.self, from: data) {
            applySnapshot(snap, persist: false)
        }
    }

    /// Aktif abonelik + premium veya family planı (backend `subscriptionPlan` / `subscriptionStatus`).
    var hasPremiumAccess: Bool {
        let status = subscriptionStatus?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard status == "active" else { return false }
        let plan = subscriptionPlan?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return plan == "premium" || plan == "family"
    }

    var hasFamilyAccess: Bool {
        let status = subscriptionStatus?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard status == "active" else { return false }
        let plan = subscriptionPlan?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return plan == "family"
    }

    var canCreateStory: Bool {
        (storyRemainingThisMonth ?? 0) > 0
    }

    var canNarrateStory: Bool {
        let voice = voiceRemainingThisMonth ?? 0
        let extra = extraVoiceCredits ?? 0
        return voice > 0 || extra > 0
    }

    func refreshFromBackend() async {
        AppLogger.info("entitlement.fetch.started", [:])
        do {
            let snapshot = try await EntitlementAPIService.fetchEntitlements()
            applySnapshot(snapshot, persist: true)
            lastSuccessfulFetchAt = Date()
            lastFetchErrorDescription = nil

                AppLogger.info("entitlement.fetch.completed", [
                    "subscriptionPlan": subscriptionPlan ?? "",
                    "subscriptionStatus": subscriptionStatus ?? "",
                    "isPremiumField": isPremiumFlag.map { $0 ? "true" : "false" } ?? "",
                    "hasPremiumAccess": hasPremiumAccess ? "true" : "false",
                    "storyRemainingThisMonth": "\(storyRemainingThisMonth ?? 0)",
                    "voiceRemainingThisMonth": "\(voiceRemainingThisMonth ?? 0)",
                    "extraVoiceCredits": "\(extraVoiceCredits ?? 0)",
                    "canNarrateStory": canNarrateStory ? "true" : "false"
                ])
        } catch {
            lastFetchErrorDescription = error.localizedDescription
            AppLogger.error("entitlement.fetch.failed", [
                "errorType": String(describing: type(of: error))
            ])
        }
    }

    func clearForLogout() {
        subscriptionPlan = nil
        subscriptionStatus = nil
        productId = nil
        currentPeriodStart = nil
        currentPeriodEnd = nil
        storyLimitMonthly = nil
        storyUsedThisMonth = nil
        storyRemainingThisMonth = nil
        voiceLimitMonthly = nil
        voiceUsedThisMonth = nil
        voiceRemainingThisMonth = nil
        extraVoiceCredits = nil
        childProfileLimit = nil
        isPremiumFlag = nil
        isFamilyFlag = nil
        lastSuccessfulFetchAt = nil
        lastFetchErrorDescription = nil
        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
    }

    private func applySnapshot(_ snap: UserEntitlementSnapshot, persist: Bool) {
        subscriptionPlan = snap.subscriptionPlan
        subscriptionStatus = snap.subscriptionStatus
        productId = snap.productId
        currentPeriodStart = snap.currentPeriodStart
        currentPeriodEnd = snap.currentPeriodEnd
        storyLimitMonthly = snap.storyLimitMonthly
        storyUsedThisMonth = snap.storyUsedThisMonth
        storyRemainingThisMonth = snap.storyRemainingThisMonth
        voiceLimitMonthly = snap.voiceLimitMonthly
        voiceUsedThisMonth = snap.voiceUsedThisMonth
        voiceRemainingThisMonth = snap.voiceRemainingThisMonth
        extraVoiceCredits = snap.extraVoiceCredits
        childProfileLimit = snap.childProfileLimit
        isPremiumFlag = snap.isPremium
        isFamilyFlag = snap.isFamily

        if persist {
            if let data = try? JSONEncoder().encode(snap) {
                UserDefaults.standard.set(data, forKey: Self.persistenceKey)
            }
        }
    }
}
