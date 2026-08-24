import Foundation

enum PortfolioAccessMode {
    /// Temporary demo mode for portfolio sharing. Keep disabled when testing real billing and entitlement flows.
    static let isEnabled = false

    static let demoCreditBalance = 999_999
    static let demoMonthlyStoryLimit = 999
    static let demoMonthlyVoiceLimit = 999
    static let demoExtraVoiceCredits = 999
}
