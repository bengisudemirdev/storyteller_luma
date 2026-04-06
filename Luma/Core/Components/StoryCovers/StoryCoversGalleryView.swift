import SwiftUI

/// Tüm masal kapak şablonlarını tek ekranda gösterir (tasarım incelemesi / QA).
struct StoryCoversGalleryView: View {
    private struct DemoItem: Identifiable {
        var id: String { type.rawValue }
        let type: StoryCoverTemplateType
        let title: String
        let subtitle: String?
        let tag: String
    }

    private let demos: [DemoItem] = [
        DemoItem(type: .sleep, title: "Ay Dede’nin Uykulu Bahçesi", subtitle: "Yıldızların altında sessiz bir bahçe", tag: "Uyku öncesi"),
        DemoItem(type: .forest, title: "Minik Tavşanın Orman Yolu", subtitle: "Yumuşak ışıkta bir patika", tag: "Macera"),
        DemoItem(type: .castle, title: "Altın Kule’nin Sırrı", subtitle: "Uzak diyarlardan bir masal", tag: "Klasik"),
        DemoItem(type: .friendship, title: "İki Arkadaş ve Güneşli Gün", subtitle: "Paylaşmanın sıcaklığı", tag: "Dostluk"),
        DemoItem(type: .space, title: "Luna ile Yıldızlara Yolculuk", subtitle: "Hayal gücüyle sonsuzluk", tag: "Keşif"),
        DemoItem(type: .ocean, title: "Deniz Kızının Sessiz Şarkısı", subtitle: "Dalgaların ninnisi", tag: "Sakin")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                Text("Masal kapak şablonları")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: "2C2A32"))
                    .padding(.horizontal, 4)

                Text("Olia görsel sistemi — 6 tema, tek ürün dili.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "6B6560"))
                    .padding(.horizontal, 4)

                ForEach(demos) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(item.type.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: "8B8580"))
                                .textCase(.uppercase)
                                .tracking(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        StoryCoverTemplateView(
                            type: item.type,
                            title: item.title,
                            subtitle: item.subtitle,
                            tag: item.tag,
                            width: cardWidth
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "FAF6EF"), Color(hex: "F0E8E0")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Kapaklar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width - 56, 260)
    }
}

#Preview("Kapak galerisi") {
    NavigationStack {
        StoryCoversGalleryView()
    }
}
