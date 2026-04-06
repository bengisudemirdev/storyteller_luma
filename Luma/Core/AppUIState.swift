import Foundation
import Combine

final class AppUIState: ObservableObject {
    @Published var isTabBarVisible: Bool = true
}

