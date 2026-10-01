import SwiftUI

/// Okuma ekranlarında metin kartının ÜSTÜNDE, kartla aynı genişlikte duran kapak görseli.
/// Dikey (3:4) kapak görseli ortadan kırpılarak yatay bir banner'a dönüştürülür; alt kenarda yumuşak geçiş ve etiket yer alır.
/// Eskiden kapak, kartın dışında küçük ve ortada duran ayrı bir dikey kart olarak çiziliyordu (metinle uyumsuz görünüyordu).
struct StoryHeroBanner: View {
    let imageURL: URL?
    let fallbackTemplate: StoryCoverTemplateType
    let title: String
    var tag: String?
    var height: CGFloat

    /// Kart genişliğine göre banner yüksekliği (küçük telefonda metne daha çok yer kalsın).
    static func height(forCardWidth width: CGFloat) -> CGFloat {
        min(230, max(160, width * 0.5))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                StoryPhotoCoverView(
                    imageURL: imageURL,
                    fallbackTemplate: fallbackTemplate,
                    title: title,
                    subtitle: nil,
                    tag: nil,
                    showsTextOverlay: false,
                    cornerRadius: 0,
                    width: geo.size.width
                )
                // Dikey görsel, yatay banner çerçevesine ortadan kırpılır.
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                // Karakterler genellikle görselin üst-ortasında: kırpma biraz yukarı hizalanır (baş kesilmesin).
                .offset(y: geo.size.height * 0.12)
                .clipped()

                // Kartın krem zeminine yumuşak geçiş.
                LinearGradient(
                    colors: [Color.clear, HomeDashboardPalette.dashboardCanvas.opacity(0.92)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                if let tag, !tag.isEmpty {
                    Text(tag)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.92)))
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                        .padding(.leading, 18)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(height: height)
    }
}

extension StoryCoverTemplateType {
    /// Kullanıcının ürettiği masalın temasına uygun hazır kapak şablonu.
    static func forTheme(_ theme: String?) -> StoryCoverTemplateType {
        switch (theme ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "uyku", "sleep": return .sleep
        case "dostluk", "arkadaşlık", "friendship": return .friendship
        case "eğitici", "umut", "forest", "orman": return .forest
        case "macera", "adventure": return .castle
        case "uzay", "space": return .space
        case "deniz", "ocean", "denizaltı", "deniz alti": return .ocean
        default: return .sleep
        }
    }
}

/// Üstte banner, altında metin içeren tek parça okuma kartı.
struct StoryReadingHeroCard<Banner: View, Content: View>: View {
    var minHeight: CGFloat? = nil
    @ViewBuilder var banner: () -> Banner
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            banner()
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
        }
        .frame(minHeight: minHeight, alignment: .topLeading)
        .background(StoryPaperBackground())
        .clipShape(RoundedRectangle(cornerRadius: StoryReadingChrome.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: StoryReadingChrome.cardCornerRadius, style: .continuous)
                .strokeBorder(StoryReadingPalette.paperEdge, lineWidth: 1)
        )
    }
}
