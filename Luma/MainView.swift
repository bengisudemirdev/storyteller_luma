import SwiftUI

struct MainView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var appUIState = AppUIState()

    var body: some View {
        ZStack(alignment: .bottom) {
            LumaTheme.bg.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .create:
                    CreateStoryView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(appUIState)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)

            if appUIState.isTabBarVisible {
                LumaTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    MainView()
}
