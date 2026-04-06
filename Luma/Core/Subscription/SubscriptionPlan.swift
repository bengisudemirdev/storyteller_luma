import Foundation

enum SubscriptionPlan: String, Codable {
    case free
    case premium
}

struct SubscriptionLimits {
    let maxChildren: Int?
    let maxDailyStories: Int?
    let maxSavedStories: Int?
}

extension SubscriptionPlan {
    var limits: SubscriptionLimits {
        switch self {
        case .free:
            return SubscriptionLimits(
                maxChildren: 1,
                maxDailyStories: 3,
                maxSavedStories: 10
            )
        case .premium:
            return SubscriptionLimits(
                maxChildren: nil,
                maxDailyStories: nil,
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

