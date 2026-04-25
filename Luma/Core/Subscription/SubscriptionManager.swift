import Foundation
import Combine
import RevenueCat

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var plan: SubscriptionPlan = .free
    @Published private(set) var status: String = "inactive"
    @Published private(set) var currentPeriodEnd: Date?
    @Published private(set) var weeklyStoriesUsed: Int = 0
    @Published private(set) var weeklyNarrationsUsed: Int = 0
    @Published private(set) var freeNarrationTrialUsed: Bool = false

    private let weeklyStoriesKey = "luma_weekly_stories_used"
    private let weeklyNarrationsKey = "luma_weekly_narrations_used"
    private let usageWeekKey = "luma_usage_week_key"
    private let freeNarrationTrialKey = "luma_free_narration_trial_used"
    private let userDefaults = UserDefaults.standard

    /// RevenueCat'te tanımlı entitlement adı
    private let premiumEntitlementId = "oliapremium"

    init() {
        loadLocalUsage()
    }

    /// RevenueCat üzerinden planı yenile
    func refreshPlanFromServer() async {
        do {
            let subscription = try await SubscriptionAPIService.getStatus()
            let normalizedStatus = subscription.status.lowercased()
            status = normalizedStatus
            currentPeriodEnd = Self.parseServerDate(subscription.currentPeriodEnd)
            if subscription.plan.lowercased() == "premium" && normalizedStatus == "active" {
                plan = .premium
            } else {
                plan = .free
            }
        } catch {
            status = "unknown"
            currentPeriodEnd = nil
            // Fallback: RevenueCat (legacy safety net) + local usage cache
            do {
                let info = try await Purchases.shared.customerInfo()
                if info.entitlements.active[premiumEntitlementId] != nil
                    || info.entitlements.active["lumapremium"] != nil
                    || info.entitlements.active["premium"] != nil {
                    plan = .premium
                } else {
                    plan = .free
                }
            } catch {
                plan = .free
            }
        }
        resetWeeklyUsageIfNeeded()
    }

    // MARK: - Story limits (weekly)

    func canGenerateStory() -> Bool {
        resetWeeklyUsageIfNeeded()
        guard let max = plan.limits.maxWeeklyStories else { return true }
        return weeklyStoriesUsed < max
    }

    func registerStoryGenerated() {
        resetWeeklyUsageIfNeeded()
        weeklyStoriesUsed += 1
        userDefaults.set(weeklyStoriesUsed, forKey: weeklyStoriesKey)
    }

    // MARK: - Narration limits (weekly premium, free one-time trial)

    func canStartNarration() -> Bool {
        resetWeeklyUsageIfNeeded()
        switch plan {
        case .premium:
            guard let max = plan.limits.maxWeeklyNarrations else { return true }
            return weeklyNarrationsUsed < max
        case .free:
            return !freeNarrationTrialUsed
        }
    }

    func registerNarrationUsed() {
        resetWeeklyUsageIfNeeded()
        switch plan {
        case .premium:
            weeklyNarrationsUsed += 1
            userDefaults.set(weeklyNarrationsUsed, forKey: weeklyNarrationsKey)
        case .free:
            freeNarrationTrialUsed = true
            userDefaults.set(true, forKey: freeNarrationTrialKey)
        }
    }

    // MARK: - Local usage persistence

    private func loadLocalUsage() {
        freeNarrationTrialUsed = userDefaults.bool(forKey: freeNarrationTrialKey)
        resetWeeklyUsageIfNeeded()
        weeklyStoriesUsed = userDefaults.integer(forKey: weeklyStoriesKey)
        weeklyNarrationsUsed = userDefaults.integer(forKey: weeklyNarrationsKey)
    }

    private func resetWeeklyUsageIfNeeded() {
        let currentWeek = Self.currentWeekKey()
        let storedWeek = userDefaults.string(forKey: usageWeekKey)
        if storedWeek != currentWeek {
            weeklyStoriesUsed = 0
            weeklyNarrationsUsed = 0
            userDefaults.set(currentWeek, forKey: usageWeekKey)
            userDefaults.set(0, forKey: weeklyStoriesKey)
            userDefaults.set(0, forKey: weeklyNarrationsKey)
        } else {
            weeklyStoriesUsed = userDefaults.integer(forKey: weeklyStoriesKey)
            weeklyNarrationsUsed = userDefaults.integer(forKey: weeklyNarrationsKey)
        }
    }

    private static func currentWeekKey() -> String {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        let year = calendar.component(.yearForWeekOfYear, from: now)
        let week = calendar.component(.weekOfYear, from: now)
        return "\(year)-W\(week)"
    }

    private static func parseServerDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if let date = ISO8601DateFormatter().date(from: value) {
            return date
        }
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatterWithFraction.date(from: value)
    }
}

