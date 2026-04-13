import SwiftUI

// 1. Sekme Seçeneklerini Tanımlıyoruz
enum Tab: String, CaseIterable {
    case home = "house.fill"
    case create = "plus.circle.fill" // Sihirli değnek havası için
    case profile = "person.fill"
    
    var title: String {
        switch self {
        case .home: return "Keşfet"
        case .create: return "Masal Yaz"
        case .profile: return "Profil"
        }
    }
}

struct LumaTabBar: View {
    // 2. MainView'daki seçili sekmeyi buraya bağlıyoruz
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 22, weight: .semibold))
                            .scaleEffect(selectedTab == tab ? 1.18 : 1.0)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? HomeDashboardPalette.tabActiveAmber
                                    : HomeDashboardPalette.sectionCaption.opacity(0.75)
                            )

                        if selectedTab == tab {
                            Text(tab.title)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.tabActiveAmber)
                                .transition(.opacity)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background {
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(Color.white.opacity(0.8))
            }
        }
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
    }
}

// Preview kısmında test etmek için sabit bir değer veriyoruz
#Preview {
    ZStack {
        LumaTheme.bg.ignoresSafeArea()
        LumaTabBar(selectedTab: .constant(.home))
    }
}
