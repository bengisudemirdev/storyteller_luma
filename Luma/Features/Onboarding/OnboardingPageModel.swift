import SwiftUI

/// Onboarding akışındaki sayfa kimlikleri (sıra sabit).
enum OnboardingPageModel: Int, CaseIterable, Identifiable {
    case welcome = 0
    case value
    case steps
    case storyTypes
    case finish

    var id: Int { rawValue }

    static var pageCount: Int { allCases.count }
}
