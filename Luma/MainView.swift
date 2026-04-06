import SwiftUI

struct MainView: View {
    // Sekme durumunu takip eden değişken
    @State private var selectedTab: Tab = .home
    @StateObject private var appUIState = AppUIState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. Arka Plan
            LumaTheme.bg.ignoresSafeArea()
            
            // 2. Sayfa İçerikleri
            Group {
                switch selectedTab {
                case .home:
                    HomeView() // Mevcut ana sayfan
                case .create:
                    CreateStoryView() // Masal oluşturma sayfan
                case .profile:
                    // Geçici Profil Sayfası
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(appUIState)
            // Sayfalar arası yumuşak geçiş
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // 3. Alt Tab Bar (Dosya olarak tanımladığımız)
            if appUIState.isTabBarVisible {
                LumaTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    MainView()
}
