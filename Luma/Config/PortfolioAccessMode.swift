import Foundation

enum PortfolioAccessMode {
    /// Temporary demo mode for portfolio sharing. Set this to `false` before re-enabling payments.
    static let isEnabled = true

    static let demoCreditBalance = 999_999
    static let demoMonthlyStoryLimit = 999
    static let demoMonthlyVoiceLimit = 999
    static let demoExtraVoiceCredits = 999
}
