import Foundation
import Combine
import RevenueCat

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var plan: SubscriptionPlan = .free
    @Published private(set) var dailyStoriesUsed: Int = 0

    private let dailyStoriesKey = "luma_daily_stories_used"
    private let dailyStoriesDateKey = "luma_daily_stories_date"
    private let userDefaults = UserDefaults.standard

    /// RevenueCat'te tanımlı entitlement adı
    private let premiumEntitlementId = "premium"

    init() {
        loadLocalDailyUsage()
    }

    /// RevenueCat üzerinden planı yenile
    func refreshPlanFromServer() async {
        do {
            let subscription = try await SubscriptionAPIService.getStatus()
            if subscription.plan.lowercased() == "premium" && subscription.status.lowercased() == "active" {
                plan = .premium
            } else {
                plan = .free
            }

            let usage = try await UsageAPIService.getUsage()
            dailyStoriesUsed = usage.used
        } catch {
            // Fallback: RevenueCat (legacy safety net) + local usage cache
            do {
                let info = try await Purchases.shared.customerInfo()
                if info.entitlements.active[premiumEntitlementId] != nil {
                    plan = .premium
                } else {
                    plan = .free
                }
            } catch {
                plan = .free
            }
            loadLocalDailyUsage()
        }
    }

    // MARK: - Story limits

    func canGenerateStory() -> Bool {
        guard let max = plan.limits.maxDailyStories else { return true }
        return dailyStoriesUsed < max
    }

    func registerStoryGenerated() {
        dailyStoriesUsed += 1
        userDefaults.set(dailyStoriesUsed, forKey: dailyStoriesKey)
    }

    private func loadLocalDailyUsage() {
        let today = Self.todayString()
        let storedDate = userDefaults.string(forKey: dailyStoriesDateKey)

        if storedDate != today {
            dailyStoriesUsed = 0
            userDefaults.set(today, forKey: dailyStoriesDateKey)
            userDefaults.set(0, forKey: dailyStoriesKey)
        } else {
            dailyStoriesUsed = userDefaults.integer(forKey: dailyStoriesKey)
        }
    }

    private static func todayString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
}

