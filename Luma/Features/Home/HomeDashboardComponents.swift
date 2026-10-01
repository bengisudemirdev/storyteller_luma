import SwiftUI

// MARK: - Design tokens (warm bedtime dashboard)

enum HomeDashboardPalette {
    static let cream = Color(hex: "FAF6EF")
    static let creamDeep = Color(hex: "F3EBE0")
    /// Ana sayfa dashboard tek tuval rengi (bölüm / kart zeminleri ile aynı).
    static let dashboardCanvas = Color(hex: "FFF9F2")
    /// Geriye dönük isimler (önceki gradyan uçları); artık tuval ile hizalı.
    static let screenTop = dashboardCanvas
    static let screenBottom = dashboardCanvas
    /// Bölüm alt açıklamaları (Zinc 500).
    static let sectionCaption = Color(hex: "6E5D63")

    static let nightTop = Color(hex: "2D2640")
    static let nightMid = Color(hex: "4A3F6B")
    static let nightBottom = Color(hex: "6B5B8C")
    /// Hero: daha derin gece mavisi / mor.
    static let heroDeepTop = Color(hex: "15102A")
    static let heroDeepMid = Color(hex: "241B45")
    static let heroDeepBottom = Color(hex: "3D2F6A")
    static let moonGlow = Color(hex: "FFF8E7")
    static let accentOrange = Color(hex: "E47C45")
    static let accentOrangeSoft = Color(hex: "F6B278")
    static let accentCandy = Color(hex: "FF9D7A")
    static let tabActiveAmber = Color(hex: "F59E0B")
    static let starTint = Color.white.opacity(0.92)
    static let heroTitle = Color.white
    static let heroSubtitle = Color.white.opacity(0.88)
    static let ink = Color(hex: "2C2A32")
    static let muted = Color(hex: "6B6560")
    static let cardSurface = Color.white
    static let cardShadow = Color.black.opacity(0.07)
    /// Kart gölgesi: ~0 10px 30px rgba(0,0,0,0.05)
    static let cardElevatedShadow = Color.black.opacity(0.07)
    /// Aynı renk zeminde kart sınırı (düşük kontrast).
    static let cardEdgeStroke = Color(hex: "2C2A32").opacity(0.08)
}

enum HomeDashboardMetrics {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 34
    static let heroCornerRadius: CGFloat = 28
    static let cardCornerRadius: CGFloat = 20
    static let classicCardWidth: CGFloat = 166
    static let classicCardPadding: CGFloat = 12
    /// Kapak: üst köşeler 24, alt biraz daha sıkı.
    static let classicCoverTopCorner: CGFloat = 24
    static let classicCoverBottomCorner: CGFloat = 16
    /// Kart içi yatay padding iki yandan; kapak genişliği.
    static let classicCoverInnerWidth: CGFloat = classicCardWidth - classicCardPadding * 2
    static let classicCarouselSpacing: CGFloat = 12
    /// Kapak üzerindeki başlık / etiket grubunu alt kenardan hafifçe yukarı alır.
    static let classicTaleTitleOverlayLift: CGFloat = 8
    /// `MainView`: alt sekme çubuğu ile ses mini paneli aynı yatay hizada dursun diye ortak kenar boşluğu.
    static let mainFloatingChromeHorizontalInset: CGFloat = 28
    static let quickActionCardHeight: CGFloat = 114
}

// MARK: - Shared screen chrome (Home, Profil, Masal oluştur)

/// Profil / masal oluşturma vb. ile paylaşılan sıcak krem geçiş.
struct LumaWarmScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                LumaTheme.bg,
                Color(hex: "FAF6EF"),
                Color(hex: "F5EDE4")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

/// Ana sayfa dashboard: tek düz tuval rengi (bölümlerle ton uyumu).
struct HomeMagicalScreenBackground: View {
    var body: some View {
        HomeDashboardPalette.dashboardCanvas
            .ignoresSafeArea()
    }
}

/// Gece gökyüzü hero kartının ay, bulut, yıldız ve radial “parıltı” katmanları.
struct DashboardHeroNightDecor: View {
    var body: some View {
        ZStack {
            DashboardHeroRadialSparkles()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            HomeDashboardPalette.moonGlow.opacity(0.95),
                            HomeDashboardPalette.moonGlow.opacity(0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 70
                    )
                )
                .frame(width: 88, height: 88)
                .offset(x: 118, y: -6)
                .blur(radius: 0.5)

            CloudBlob()
                .fill(Color.white.opacity(0.08))
                .frame(width: 120, height: 36)
                .offset(x: -40, y: 100)
                .blur(radius: 1)

            CloudBlob()
                .fill(Color.white.opacity(0.06))
                .frame(width: 100, height: 30)
                .offset(x: 90, y: 130)

            StarsField()

            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        HomeDashboardPalette.accentOrange.opacity(0.22),
                        HomeDashboardPalette.accentOrangeSoft.opacity(0.14)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .clipShape(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.heroCornerRadius, style: .continuous)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// Hafif yıldız parıltısı (radial gradient diskler).
private struct DashboardHeroRadialSparkles: View {
    private struct Spark: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let diameter: CGFloat
        let coreOpacity: Double
    }

    private let sparks: [Spark] = [
        Spark(id: 0, x: 0.18, y: 0.22, diameter: 42, coreOpacity: 0.55),
        Spark(id: 1, x: 0.72, y: 0.18, diameter: 36, coreOpacity: 0.45),
        Spark(id: 2, x: 0.5, y: 0.38, diameter: 28, coreOpacity: 0.35),
        Spark(id: 3, x: 0.88, y: 0.42, diameter: 22, coreOpacity: 0.4),
        Spark(id: 4, x: 0.08, y: 0.55, diameter: 26, coreOpacity: 0.32),
        Spark(id: 5, x: 0.62, y: 0.62, diameter: 34, coreOpacity: 0.38)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(sparks) { s in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(s.coreOpacity),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: s.diameter * 0.55
                        )
                    )
                    .frame(width: s.diameter, height: s.diameter)
                    .position(x: w * s.x, y: h * s.y)
                    .blur(radius: 0.8)
            }
        }
    }
}

/// Ana sayfadaki gece hero ile aynı yapı; başlık, alt başlık ve alt alan özelleştirilebilir.
struct DashboardNightHeroLayout<Footer: View>: View {
    let title: String
    let subtitle: String
    /// İkinci satır (ör. uygulama sloganı altına davet cümlesi).
    var caption: String?
    var minHeight: CGFloat = 280
    @ViewBuilder var footer: () -> Footer

    init(
        title: String,
        subtitle: String,
        caption: String? = nil,
        minHeight: CGFloat = 280,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.caption = caption
        self.minHeight = minHeight
        self.footer = footer
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.heroCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            HomeDashboardPalette.heroDeepTop,
                            HomeDashboardPalette.heroDeepMid,
                            HomeDashboardPalette.heroDeepBottom
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            HomeDashboardPalette.nightMid.opacity(0.35),
                            Color.clear,
                            HomeDashboardPalette.accentOrange.opacity(0.12)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HomeDashboardMetrics.heroCornerRadius, style: .continuous))
                )
                .overlay(DashboardHeroNightDecor())
                .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 14)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 27, weight: .bold, design: .serif))
                        .tracking(-0.4)
                        .foregroundStyle(HomeDashboardPalette.heroTitle)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.heroSubtitle)
                        .fixedSize(horizontal: false, vertical: true)

                    if let caption, !caption.isEmpty {
                        Text(caption)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.heroSubtitle.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 26)
                .padding(.horizontal, 22)

                Spacer(minLength: 18)

                footer()
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
            }
        }
        .frame(minHeight: minHeight)
    }
}

// MARK: - Hero

struct HomeHeroSection: View {
    @State private var ctaPulse = false

    var body: some View {
        DashboardNightHeroLayout(
            title: "Haydi Masal Diyarı’na Yolculuk",
            subtitle: AppBrand.subtitle,
            caption: "Bu gece birlikte güzel bir masal seçelim.",
            footer: {
                NavigationLink {
                    CreateStoryView()
                } label: {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.45))
                            .blur(radius: ctaPulse ? 12 : 6)
                            .scaleEffect(ctaPulse ? 1.06 : 1.0)
                            .opacity(ctaPulse ? 0.75 : 1)
                            .padding(.horizontal, -4)

                        HStack(spacing: 8) {
                            Text("Bu Geceki Masalı Seç")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            HomeDashboardPalette.moonGlow,
                                            HomeDashboardPalette.accentOrangeSoft.opacity(0.92)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: HomeDashboardPalette.accentOrange.opacity(0.4), radius: ctaPulse ? 16 : 10, x: 0, y: 5)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    Color.white.opacity(ctaPulse ? 0.95 : 0.55),
                                    lineWidth: ctaPulse ? 2 : 1
                                )
                        )
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                        ctaPulse = true
                    }
                }
            }
        )
    }
}

private struct CloudBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.addEllipse(in: CGRect(x: 0, y: h * 0.35, width: w * 0.45, height: h * 0.55))
        p.addEllipse(in: CGRect(x: w * 0.2, y: h * 0.2, width: w * 0.5, height: h * 0.65))
        p.addEllipse(in: CGRect(x: w * 0.45, y: h * 0.3, width: w * 0.5, height: h * 0.6))
        return p
    }
}

private struct StarsField: View {
    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    private let stars: [Star] = [
        Star(x: 0.12, y: 0.18, size: 3, opacity: 0.85),
        Star(x: 0.28, y: 0.12, size: 2, opacity: 0.65),
        Star(x: 0.72, y: 0.22, size: 2.5, opacity: 0.75),
        Star(x: 0.88, y: 0.16, size: 2, opacity: 0.55),
        Star(x: 0.55, y: 0.08, size: 2, opacity: 0.5),
        Star(x: 0.18, y: 0.42, size: 2, opacity: 0.45),
        Star(x: 0.92, y: 0.4, size: 3, opacity: 0.6)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { s in
                Image(systemName: "sparkle")
                    .font(.system(size: s.size))
                    .foregroundStyle(HomeDashboardPalette.starTint.opacity(s.opacity))
                    .position(x: geo.size.width * s.x, y: geo.size.height * s.y)
            }
        }
    }
}

// MARK: - Classic tales

struct ClassicTaleCard: View {
    let tale: ClassicTaleItem

    private var classicCoverURL: URL? {
        tale.resolvedCoverImageURL
    }

    private var coverClip: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: HomeDashboardMetrics.classicCoverTopCorner,
                bottomLeading: HomeDashboardMetrics.classicCoverBottomCorner,
                bottomTrailing: HomeDashboardMetrics.classicCoverBottomCorner,
                topTrailing: HomeDashboardMetrics.classicCoverTopCorner
            ),
            style: .continuous
        )
    }

    var body: some View {
        NavigationLink {
            ClassicTalePreviewView(tale: tale)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                StoryPhotoCoverView(
                    imageURL: classicCoverURL,
                    fallbackTemplate: tale.coverTemplate,
                    title: tale.title,
                    subtitle: nil,
                    tag: tale.tag,
                    showsTextOverlay: true,
                    titleOverlayExtraBottomInset: HomeDashboardMetrics.classicTaleTitleOverlayLift,
                    cornerRadius: HomeDashboardMetrics.classicCoverTopCorner,
                    width: HomeDashboardMetrics.classicCoverInnerWidth
                )
                .clipShape(coverClip)
                // Uzak kapakta başlık zaten StoryPhotoCoverView içinde; şablon modunda eski derinlik için hafif gradyan.
                .overlay {
                    if classicCoverURL == nil {
                        coverClip
                            .fill(
                                LinearGradient(
                                    colors: [
                                        HomeDashboardPalette.accentCandy.opacity(0.08),
                                        HomeDashboardPalette.nightMid.opacity(0.22)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .allowsHitTesting(false)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Masal zamanı")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(HomeDashboardPalette.accentOrange.opacity(0.12))
                )

                // Özet 1 ya da 2 satır olabilir; sabit 2 satırlık yükseklik tüm kartları aynı boya getirir.
                Text(tale.teaser)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .topLeading)
            }
            .padding(HomeDashboardMetrics.classicCardPadding)
            .frame(width: HomeDashboardMetrics.classicCardWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                HomeDashboardPalette.cream.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 3, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                HomeDashboardPalette.accentOrange.opacity(0.22),
                                HomeDashboardPalette.cardEdgeStroke
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 8)
            .shadow(color: HomeDashboardPalette.accentCandy.opacity(0.13), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                .opacity(phase.isIdentity ? 1 : 0.92)
        }
    }
}

/// Klasik masallar yatay karuseli için sayfa göstergesi (kaydırma ile senkron).
private struct ClassicTalesCarouselPageIndicator: View {
    let currentIndex: Int
    let pageCount: Int

    var body: some View {
        StoryReadingPageDots(currentIndex: currentIndex, pageCount: pageCount)
    }
}

struct ClassicTalesSection: View {
    let classicTales: [ClassicTaleItem]

    @State private var scrollPositionId: String?
    @State private var isInfoBubbleVisible = false

    private var carouselTales: [ClassicTaleItem] {
        Array(classicTales.prefix(10))
    }

    private var currentCarouselPageIndex: Int {
        guard let id = scrollPositionId,
              let idx = carouselTales.firstIndex(where: { $0.id == id }) else {
            return 0
        }
        return idx
    }

    private var showsPagination: Bool {
        carouselTales.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Klasik Masallar")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .tracking(-0.6)
                        .foregroundStyle(HomeDashboardPalette.ink)

                    Text("Sevilen klasik masalları keşfet")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                }

                Spacer(minLength: 8)

                NavigationLink {
                    ClassicTalesLibraryView(tales: classicTales)
                } label: {
                    Text("Tümünü Gör")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                }
                .buttonStyle(.plain)
            }

            if isInfoBubbleVisible {
                HStack(alignment: .top, spacing: 8) {
                    Text("Bu masallar çocuk gelişimi ve pedagojik değerlere uygun olacak şekilde seçilip yumuşak bir dille düzenlenmiştir; uyku öncesi için sakin ve güvenli bir ton hedeflenir.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 4)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isInfoBubbleVisible = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.74))
                )
                .overlay(alignment: .topLeading) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.74))
                        .rotationEffect(.degrees(180))
                        .offset(x: 156, y: -8)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: HomeDashboardMetrics.classicCarouselSpacing) {
                    ForEach(carouselTales) { tale in
                        ClassicTaleCard(tale: tale)
                            .id(tale.id)
                    }
                }
                .padding(.vertical, 6)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollPositionId)
            .contentMargins(.horizontal, 0, for: .scrollContent)
            .onAppear {
                if scrollPositionId == nil, let first = carouselTales.first {
                    scrollPositionId = first.id
                }
            }
            .onChange(of: carouselTales.map(\.id)) { _, newIds in
                guard !newIds.isEmpty else {
                    scrollPositionId = nil
                    return
                }
                if let id = scrollPositionId, newIds.contains(id) { return }
                scrollPositionId = newIds.first
            }

            if showsPagination {
                ClassicTalesCarouselPageIndicator(
                    currentIndex: currentCarouselPageIndex,
                    pageCount: carouselTales.count
                )
                .padding(.top, 2)
            }

        }
    }
}


/// Klasik masal kartına basınca açılan tam metin okuma ekranı.
struct ClassicTalePreviewView: View {
    let tale: ClassicTaleItem
    @State private var currentPage = 0
    @State private var activeAudioURLString: String?
    @State private var isRequestingNarration = false
    @State private var narrationErrorMessage: String?
    @State private var showFloatingAudioPanel = false
    @State private var classicDetailDiscoveryDone = false
    @State private var isLoadingClassicDetail = false
    @State private var showClassicPaywall = false
    @State private var classicNarratePaymentBlocked = false
    @AppStorage("classic_tale_audio_panel_dx") private var audioPanelStoredDX: Double = 0
    @AppStorage("classic_tale_audio_panel_dy") private var audioPanelStoredDY: Double = 0
    @GestureState private var audioPanelDragTranslation: CGSize = .zero
    @StateObject private var audioPlayer = AudioPlayerViewModel()
    @EnvironmentObject private var appUIState: AppUIState

    /// Her sayfa paragraf listesidir; gerçek ekran boyutu ölçülünce yeniden hesaplanır.
    @State private var pages: [[String]] = []
    @State private var lastPaginatedSize: CGSize = .zero

    private var displayPages: [[String]] {
        pages.isEmpty ? StoryReadingPagination.fallbackPages(from: tale.fullStory) : pages
    }

    private var pageCount: Int {
        max(displayPages.count, 1)
    }

    private enum ClassicReaderMetrics {
        static let topInset: CGFloat = 8
        static let bottomInset: CGFloat = 12
        static let innerPadding: CGFloat = 22
        static let contentSpacing: CGFloat = 14
        static let coverSpacing: CGFloat = 14
        /// Son sayfadaki kaynak/atıf satırı için ayrılan pay.
        static let attributionReserve: CGFloat = 44
        /// Etiket kapsülü (12pt + dikey dolgu).
        static let tagHeight: CGFloat = 27
    }

    private func repaginate(for size: CGSize) {
        guard size.width > 1, size.height > 1, size != lastPaginatedSize else { return }
        lastPaginatedSize = size
        let outerWidth = min(size.width - StoryReadingChrome.horizontalPadding * 2, StoryReadingChrome.cardMaxOuterWidth)
        let textWidth = outerWidth - ClassicReaderMetrics.innerPadding * 2
        let cardHeight = size.height - ClassicReaderMetrics.topInset - ClassicReaderMetrics.bottomInset
        let innerHeight = cardHeight - ClassicReaderMetrics.innerPadding * 2
        // İlk sayfada kartın üstünde banner var; etiket banner'ın üstünde olduğu için başlık bloğunda yer almaz.
        let coverBlock = StoryHeroBanner.height(forCardWidth: outerWidth)
        let titleBlock = 12 + 10 + StoryTextMetrics.titleHeight(tale.title, width: textWidth)
            + ClassicReaderMetrics.contentSpacing

        func paginate(reserve: CGFloat) -> [[String]] {
            StoryReadingPagination.pages(
                from: tale.fullStory,
                textWidth: textWidth,
                firstPageHeight: innerHeight - coverBlock - titleBlock - reserve,
                otherPageHeight: innerHeight - reserve
            )
        }

        // Sayfalar sonuna kadar dolsun: kaynak satırı için yer yalnızca son sayfa sığmıyorsa ayrılır.
        var result = paginate(reserve: 0)
        if let last = result.last {
            let lastIndex = result.count - 1
            let lastHeight = last.reduce(CGFloat(0)) { $0 + StoryTextMetrics.bodyHeight($1, width: textWidth) }
                + CGFloat(max(last.count - 1, 0)) * StoryReadingPagination.paragraphSpacing
            let available = lastIndex == 0 ? innerHeight - coverBlock - titleBlock : innerHeight
            if lastHeight + ClassicReaderMetrics.attributionReserve > available * 0.975 {
                result = paginate(reserve: ClassicReaderMetrics.attributionReserve)
            }
        }
        pages = result
        currentPage = min(currentPage, max(pages.count - 1, 0))
    }

    private var coverWidth: CGFloat {
        min(UIScreen.main.bounds.width - 48, 148)
    }

    private var hasPlayableClassicAudioURL: Bool {
        guard let s = activeAudioURLString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return false }
        return true
    }

    private var needsMasalSeslendirButton: Bool {
        classicDetailDiscoveryDone
            && !hasPlayableClassicAudioURL
            && !isLoadingClassicDetail
            && !isRequestingNarration
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                StoryReadingWarmBackground()

                VStack(spacing: 0) {
                    GeometryReader { proxy in
                    TabView(selection: $currentPage) {
                        ForEach(Array(displayPages.enumerated()), id: \.offset) { index, paragraphs in
                            ScrollView(showsIndicators: false) {
                                let cardWidth = min(proxy.size.width - StoryReadingChrome.horizontalPadding * 2, StoryReadingChrome.cardMaxOuterWidth)
                                let cardMinHeight = proxy.size.height - ClassicReaderMetrics.topInset - ClassicReaderMetrics.bottomInset

                                Group {
                                    if index == 0 {
                                        // Kapak: kartın üstünde tam genişlikte banner (eskiden ortada duran küçük, ayrı bir kart).
                                        StoryReadingHeroCard(minHeight: cardMinHeight) {
                                            StoryHeroBanner(
                                                imageURL: tale.resolvedCoverImageURL,
                                                fallbackTemplate: tale.coverTemplate,
                                                title: tale.title,
                                                tag: tale.tag,
                                                height: StoryHeroBanner.height(forCardWidth: cardWidth)
                                            )
                                        } content: {
                                            VStack(alignment: .leading, spacing: 14) {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    StoryOrnamentDivider()
                                                        .frame(height: 12)

                                                    Text(tale.title)
                                                        .font(.system(size: StoryReadingChrome.titleSize, weight: .bold, design: .serif))
                                                        .foregroundStyle(StoryReadingPalette.ink)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                }

                                                StoryPageBody(paragraphs: paragraphs)

                                                if index == displayPages.count - 1 {
                                                    Text(tale.attribution)
                                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                                        .foregroundStyle(HomeDashboardPalette.muted)
                                                        .italic()
                                                        .padding(.top, 8)
                                                }
                                            }
                                        }
                                    } else {
                                        StoryReadingTextCard(minHeight: cardMinHeight) {
                                            VStack(alignment: .leading, spacing: 14) {
                                                StoryPageBody(paragraphs: paragraphs)

                                                if index == displayPages.count - 1 {
                                                    Text(tale.attribution)
                                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                                        .foregroundStyle(HomeDashboardPalette.muted)
                                                        .italic()
                                                        .padding(.top, 8)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: StoryReadingChrome.cardMaxOuterWidth)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, StoryReadingChrome.horizontalPadding)
                                .padding(.top, ClassicReaderMetrics.topInset)
                                .padding(.bottom, ClassicReaderMetrics.bottomInset)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onAppear { repaginate(for: proxy.size) }
                    .onChange(of: proxy.size) { _, newSize in repaginate(for: newSize) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    StoryReadingPageControls(currentPage: $currentPage, pageCount: pageCount)
                }
            }

            if showFloatingAudioPanel {
                classicFloatingAudioPanel
                    .padding(.horizontal, HomeDashboardMetrics.mainFloatingChromeHorizontalInset)
                    .padding(.bottom, 10)
                    .offset(audioPanelDisplayedOffset)
                    .gesture(audioPanelDragGesture)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showFloatingAudioPanel)
            }
        }
        // Başlık zaten kartta; üst çubukta tekrarlanmasın.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(HomeDashboardPalette.dashboardCanvas.opacity(0.94), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFloatingAudioPanel = true
                    Task { await prepareClassicAudioPanel() }
                } label: {
                    if isRequestingNarration || isLoadingClassicDetail {
                        ProgressView()
                            .tint(HomeDashboardPalette.accentOrange)
                    } else {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            appUIState.isTabBarVisible = false
            currentPage = min(currentPage, max(pageCount - 1, 0))
            audioPlayer.nowPlayingTitle = tale.title
            classicDetailDiscoveryDone = false
            classicNarratePaymentBlocked = false
            narrationErrorMessage = nil
            if let u = tale.audioURL?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty {
                activeAudioURLString = u
            }
        }
        .onDisappear {
            appUIState.isTabBarVisible = true
            audioPlayer.stop()
            audioPlayer.cleanup()
            showFloatingAudioPanel = false
            classicDetailDiscoveryDone = false
            classicNarratePaymentBlocked = false
        }
        .sheet(isPresented: $showClassicPaywall) {
            if !PortfolioAccessMode.isEnabled {
                PaywallView(
                    source: .insufficientCredits(required: CreditCost.narration),
                    onPurchaseCompleted: {
                        Task {
                            await EntitlementStore.shared.refreshFromBackend()
                            await SubscriptionManager.shared.refreshPlanFromServer()
                            if !hasPlayableClassicAudioURL {
                                await narrateClassicTaleFromButton()
                            }
                        }
                    }
                )
            }
        }
    }

    private var audioPanelDisplayedOffset: CGSize {
        let raw = CGSize(
            width: CGFloat(audioPanelStoredDX) + audioPanelDragTranslation.width,
            height: CGFloat(audioPanelStoredDY) + audioPanelDragTranslation.height
        )
        let clamped = Self.clampClassicAudioPanelOffset(dx: Double(raw.width), dy: Double(raw.height))
        return CGSize(width: clamped.0, height: clamped.1)
    }

    private var audioPanelDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .updating($audioPanelDragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                var nextX = audioPanelStoredDX + Double(value.translation.width)
                var nextY = audioPanelStoredDY + Double(value.translation.height)
                let clamped = Self.clampClassicAudioPanelOffset(dx: nextX, dy: nextY)
                audioPanelStoredDX = clamped.0
                audioPanelStoredDY = clamped.1
            }
    }

    private static func clampClassicAudioPanelOffset(dx: Double, dy: Double) -> (Double, Double) {
        let maxAbsX: Double = 150
        let minY: Double = -420
        let maxY: Double = 80
        let x = min(max(dx, -maxAbsX), maxAbsX)
        let y = min(max(dy, minY), maxY)
        return (x, y)
    }

    private var classicFloatingAudioPanel: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(HomeDashboardPalette.muted.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 2)
                .accessibilityLabel(String(localized: "Paneli sürükleyerek taşı"))

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(HomeDashboardPalette.accentOrange.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tale.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .lineLimit(1)
                    if isLoadingClassicDetail {
                        Text("Masal yükleniyor…")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    } else if isRequestingNarration {
                        Text("Hazırlanıyor…")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    } else if let err = audioPlayer.errorMessage, !err.isEmpty {
                        Text(err)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.88))
                            .lineLimit(2)
                    } else if let narrationErrorMessage, !narrationErrorMessage.isEmpty {
                        Text(narrationErrorMessage)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.88))
                            .lineLimit(2)
                    } else if hasPlayableClassicAudioURL {
                        Text(audioPlayer.isPlaying ? "Duraklat" : "Dinle")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    } else if needsMasalSeslendirButton {
                        Text("Ses için masalı seslendirebilirsin.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    } else {
                        Text("Ses hazırlanıyor…")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showFloatingAudioPanel = false
                    narrationErrorMessage = nil
                    classicNarratePaymentBlocked = false
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.muted.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Kapat"))
            }

            HStack(spacing: 18) {
                Button {
                    audioPlayer.skipBackward(seconds: 15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.ink)
                }
                .buttonStyle(.plain)
                .disabled(isRequestingNarration || !hasPlayableClassicAudioURL)

                Button {
                    if let url = activeAudioURLString, !url.isEmpty {
                        audioPlayer.toggle(urlString: url)
                        narrationErrorMessage = nil
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        if hasPlayableClassicAudioURL {
                            Text(audioPlayer.isPlaying ? "Duraklat" : "Dinle")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        }
                    }
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .disabled(isRequestingNarration || !hasPlayableClassicAudioURL)

                Button {
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
                .buttonStyle(.plain)
                .disabled(isRequestingNarration)
            }
            .frame(maxWidth: .infinity)

            if needsMasalSeslendirButton {
                Button {
                    Task { await narrateClassicTaleFromButton() }
                } label: {
                    Text("Masalı Seslendir")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(HomeDashboardPalette.accentOrange)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isRequestingNarration)
                .padding(.top, 4)
            }

            if classicNarratePaymentBlocked && !PortfolioAccessMode.isEnabled {
                Button {
                    showClassicPaywall = true
                } label: {
                    Text("Paketleri Gör")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(HomeDashboardPalette.dashboardCanvas)
                .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
        )
    }

    /// Hoparlör: önce mevcut URL veya `GET` detay; yoksa panelde «Masalı Seslendir» gösterilir (`POST …/narrate` ayrı).
    private func prepareClassicAudioPanel() async {
        AppLogger.info("narration.classic.flow_started", ["taleId": tale.id, "titleSnippet": String(tale.title.prefix(40))])
        narrationErrorMessage = nil
        classicNarratePaymentBlocked = false

        if let u = activeAudioURLString?.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty {
            AppLogger.info("narration.classic.play_state_url", ["taleId": tale.id].merging(AppLogger.narrationURLSummaryFields(u)) { _, new in new })
            audioPlayer.play(urlString: u)
            classicDetailDiscoveryDone = true
            return
        }

        if let existing = tale.audioURL?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines), !existing.isEmpty {
            AppLogger.info("narration.classic.play_list_item_url", ["taleId": tale.id].merging(AppLogger.narrationURLSummaryFields(existing)) { _, new in new })
            activeAudioURLString = existing
            audioPlayer.play(urlString: existing)
            classicDetailDiscoveryDone = true
            return
        }

        isLoadingClassicDetail = true
        defer { isLoadingClassicDetail = false }

        do {
            if let detail = try await ClassicTalesAPIService.fetchClassicTaleDetail(taleId: tale.id),
               let remoteURL = detail.audioURL?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines),
               !remoteURL.isEmpty {
                AppLogger.info("narration.classic.play_detail_url", ["taleId": tale.id].merging(AppLogger.narrationURLSummaryFields(remoteURL)) { _, new in new })
                activeAudioURLString = remoteURL
                audioPlayer.play(urlString: remoteURL)
            } else {
                AppLogger.info("narration.classic.detail_no_audio_url", ["taleId": tale.id])
            }
        } catch {
            AppLogger.error("narration.classic.detail_fetch_failed", [
                "taleId": tale.id,
                "errorType": String(describing: type(of: error)),
                "apiCode": (error as? APIClientError)?.serverErrorCode ?? "",
                "message": error.localizedDescription
            ])
            narrationErrorMessage = error.localizedDescription
            #if DEBUG
            if let code = (error as? APIClientError)?.serverErrorCode {
                narrationErrorMessage = "\(error.localizedDescription) (\(code))"
            }
            #endif
        }
        classicDetailDiscoveryDone = true
    }

    private func narrateClassicTaleFromButton() async {
        narrationErrorMessage = nil
        classicNarratePaymentBlocked = false
        isRequestingNarration = true
        defer { isRequestingNarration = false }

        do {
            let url = try await ClassicTalesAPIService.narrateClassicTale(taleId: tale.id)
            activeAudioURLString = url
            audioPlayer.play(urlString: url)
        } catch let error as APIClientError {
            if case .paymentRequired = error {
                classicNarratePaymentBlocked = !PortfolioAccessMode.isEnabled
                narrationErrorMessage = PortfolioAccessMode.isEnabled
                    ? "Sesli masal şu an hazırlanamadı. Lütfen biraz sonra tekrar deneyin."
                    : "Sesli masal hakkın bitti."
                return
            }
            if case .unauthorized = error {
                narrationErrorMessage = "Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap."
                return
            }
            narrationErrorMessage = "Sesli masal hazırlanamadı. Lütfen tekrar deneyin."
        } catch {
            narrationErrorMessage = "Sesli masal hazırlanamadı. Lütfen tekrar deneyin."
        }
    }
}

// MARK: - Create story card

struct DashboardQuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                NavigationLink {
                    CreateStoryView()
                } label: {
                    quickActionCard(
                        icon: "wand.and.stars",
                        title: "Yeni Masal Oluştur",
                        subtitle: "Hızlıca kişisel bir masal hazırla",
                        gradient: [HomeDashboardPalette.accentOrange, HomeDashboardPalette.accentOrangeSoft]
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SavedStoriesLibraryView()
                } label: {
                    quickActionCard(
                        icon: "books.vertical.fill",
                        title: "Kütüphanem",
                        subtitle: "Kayıtlı masallara devam et",
                        gradient: [HomeDashboardPalette.nightMid, HomeDashboardPalette.heroDeepBottom]
                    )
                }
                .buttonStyle(.plain)
            }
            // İki kart aynı yükseklikte olsun (metin uzunluğuna göre farklı boylanıyorlardı).
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func quickActionCard(
        icon: String,
        title: String,
        subtitle: String,
        gradient: [Color]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.96))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(2)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.86))
                .lineLimit(2)
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            minHeight: HomeDashboardMetrics.quickActionCardHeight,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}


// MARK: - Recent stories (dashboard styling)

struct DashboardRecentStoriesSection: View {
    let stories: [StoryModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Sana Özel")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(HomeDashboardPalette.accentOrange.opacity(0.12))
                    )

                    Text("Son Masalların")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .tracking(-0.6)
                        .foregroundStyle(HomeDashboardPalette.ink)

                    Text("Kayıtlı masallarına buradan devam et")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                }

                Spacer(minLength: 8)

                NavigationLink {
                    SavedStoriesLibraryView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Tümünü Gör")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(HomeDashboardPalette.accentOrange.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }

            if stories.isEmpty {
                NavigationLink(destination: CreateStoryView()) {
                    HStack(spacing: 14) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(HomeDashboardPalette.accentOrange.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Henüz kaydedilmiş masal yok")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.ink)
                            Text("İlk masalını oluştur ve buradan tekrar oku.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        }
                        Spacer()
                        Text("Masal Oluştur")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(HomeDashboardPalette.accentOrange.opacity(0.13))
                            )
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 3, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        HomeDashboardPalette.cream.opacity(0.92)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 3, style: .continuous)
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeDashboardMetrics.classicCarouselSpacing) {
                        ForEach(stories.prefix(10)) { story in
                            NavigationLink(
                                destination: StoryReaderView(
                                    child: nil,
                                    storyTitle: story.title,
                                    storyContent: story.content,
                                    showSaveButton: false,
                                    story: story,
                                    onSave: nil
                                )
                            ) {
                                DashboardRecentStoryCard(story: story)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }
}

private struct DashboardRecentStoryCard: View {
    let story: StoryModel

    private var thumbShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: HomeDashboardMetrics.classicCoverTopCorner,
                bottomLeading: 14,
                bottomTrailing: 14,
                topTrailing: HomeDashboardMetrics.classicCoverTopCorner
            ),
            style: .continuous
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                thumbShape
                    .fill(
                        LinearGradient(
                            colors: [
                                HomeDashboardPalette.accentOrange.opacity(0.28),
                                HomeDashboardPalette.accentOrangeSoft.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let urlStr = story.cover_image_url, let url = URL(string: urlStr) {
                    CachedRemoteImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        if story.cover_image_url?.isEmpty == false {
                            ProgressView()
                                .tint(HomeDashboardPalette.accentOrange)
                        } else {
                            EmptyView()
                        }
                    }
                }

                LinearGradient(
                    colors: [
                        HomeDashboardPalette.accentCandy.opacity(0.12),
                        HomeDashboardPalette.accentOrange.opacity(0.08),
                        HomeDashboardPalette.nightMid.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(thumbShape)
                .allowsHitTesting(false)

                if story.cover_image_url == nil || story.cover_image_url?.isEmpty == true {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 102)
            .clipShape(thumbShape)

            Text(story.title)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
                .lineLimit(2)

            if let date = story.created_at {
                Text(Self.dateFormatter.string(from: date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
            }

            HStack(spacing: 4) {
                Text("Devam et")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(HomeDashboardPalette.accentOrange)
        }
        .padding(14)
        .frame(width: 172, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            HomeDashboardPalette.cream.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 3, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            HomeDashboardPalette.accentOrange.opacity(0.22),
                            HomeDashboardPalette.cardEdgeStroke
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 8)
        .shadow(color: HomeDashboardPalette.accentCandy.opacity(0.12), radius: 10, x: 0, y: 4)
        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                .opacity(phase.isIdentity ? 1 : 0.92)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    }()
}
