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
                    // Tıklandığında yaylanma efektiyle sekmeyi değiştir
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 22, weight: .semibold))
                            // Seçiliyse ikon parlar ve büyür
                            .scaleEffect(selectedTab == tab ? 1.2 : 1.0)
                            .foregroundColor(selectedTab == tab ? LumaTheme.lavender : LumaTheme.text.opacity(0.4))
                        
                        if selectedTab == tab {
                            Text(tab.title)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(LumaTheme.lavender)
                                .transition(.opacity) // Yazı yumuşakça belirir
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background(
            // 3. Yüzen Kapsül Tasarımı
            Capsule()
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        )
        .padding(.horizontal, 25)
        .padding(.bottom, 10) // iPhone çentiğinin biraz üzerinde durması için
    }
}

// Preview kısmında test etmek için sabit bir değer veriyoruz
#Preview {
    ZStack {
        LumaTheme.bg.ignoresSafeArea()
        LumaTabBar(selectedTab: .constant(.home))
    }
}
