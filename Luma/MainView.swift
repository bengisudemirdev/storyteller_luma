import SwiftUI

struct MainView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var appUIState = AppUIState()

    var body: some View {
        ZStack(alignment: .bottom) {
            LumaTheme.bg.ignoresSafeArea()

            // Sekmeler canlı tutulur (yalnızca gizlenir): geçişte ekran yeniden oluşturulup veri baştan yüklenmez,
            // spinner çıkmaz, kaydırma konumu ve yazılan metin korunur.
            ZStack {
                tabContent(.home) { HomeView() }
                tabContent(.create) { CreateStoryView(isActive: selectedTab == .create) }
                tabContent(.profile) { ProfileView(isActive: selectedTab == .profile) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(appUIState)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            if appUIState.isTabBarVisible {
                LumaTabBar(selectedTab: $selectedTab)
                    .zIndex(10)
            }
        }
    }
}

extension MainView {
    @ViewBuilder
    fileprivate func tabContent<Content: View>(_ tab: Tab, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = selectedTab == tab
        content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
    }
}

#Preview {
    MainView()
}
