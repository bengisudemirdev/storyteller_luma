import Foundation

enum SubscriptionPlan: String, Codable {
    case free
    case premium
}

struct SubscriptionLimits {
    let maxChildren: Int?
    let maxWeeklyStories: Int?
    let maxWeeklyNarrations: Int?
    let hasOneTimeNarrationTrial: Bool
    let maxSavedStories: Int?
}

extension SubscriptionPlan {
    var limits: SubscriptionLimits {
        switch self {
        case .free:
            return SubscriptionLimits(
                maxChildren: 1,
                maxWeeklyStories: 1,
                maxWeeklyNarrations: nil,
                hasOneTimeNarrationTrial: true,
                maxSavedStories: 10
            )
        case .premium:
            return SubscriptionLimits(
                maxChildren: nil,
                maxWeeklyStories: 7,
                maxWeeklyNarrations: 5,
                hasOneTimeNarrationTrial: false,
                maxSavedStories: nil
            )
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Olia Free"
        case .premium: return "Olia Premium"
        }
    }
}

