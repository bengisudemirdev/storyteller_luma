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
    static let sectionCaption = Color(hex: "71717A")

    static let nightTop = Color(hex: "2D2640")
    static let nightMid = Color(hex: "4A3F6B")
    static let nightBottom = Color(hex: "6B5B8C")
    /// Hero: daha derin gece mavisi / mor.
    static let heroDeepTop = Color(hex: "15102A")
    static let heroDeepMid = Color(hex: "241B45")
    static let heroDeepBottom = Color(hex: "3D2F6A")
    static let moonGlow = Color(hex: "FFF8E7")
    static let accentOrange = Color(hex: "E8956A")
    static let accentOrangeSoft = Color(hex: "F4B08C")
    static let tabActiveAmber = Color(hex: "F59E0B")
    static let starTint = Color.white.opacity(0.92)
    static let heroTitle = Color.white
    static let heroSubtitle = Color.white.opacity(0.88)
    static let ink = Color(hex: "2C2A32")
    static let muted = Color(hex: "6B6560")
    static let cardSurface = Color.white
    static let cardShadow = Color.black.opacity(0.07)
    /// Kart gölgesi: ~0 10px 30px rgba(0,0,0,0.05)
    static let cardElevatedShadow = Color.black.opacity(0.05)
    /// Aynı renk zeminde kart sınırı (düşük kontrast).
    static let cardEdgeStroke = Color(hex: "2C2A32").opacity(0.08)
}

enum HomeDashboardMetrics {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 28
    static let heroCornerRadius: CGFloat = 28
    static let cardCornerRadius: CGFloat = 20
    static let classicCardWidth: CGFloat = 176
    static let classicCardPadding: CGFloat = 14
    /// Kapak: üst köşeler 24, alt biraz daha sıkı.
    static let classicCoverTopCorner: CGFloat = 24
    static let classicCoverBottomCorner: CGFloat = 16
    /// Kart içi yatay padding iki yandan; kapak genişliği.
    static let classicCoverInnerWidth: CGFloat = classicCardWidth - classicCardPadding * 2
    static let classicCarouselSpacing: CGFloat = 20
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
        AppConfig.classicTaleCoverImageURL(taleId: tale.id)
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
            VStack(alignment: .leading, spacing: 12) {
                StoryPhotoCoverView(
                    imageURL: classicCoverURL,
                    fallbackTemplate: tale.coverTemplate,
                    title: tale.title,
                    subtitle: nil,
                    tag: tale.tag,
                    showsTextOverlay: true,
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
                                        Color.black.opacity(0.05),
                                        Color.black.opacity(0.32)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .allowsHitTesting(false)
                    }
                }

                Text(tale.teaser)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(HomeDashboardMetrics.classicCardPadding)
            .frame(width: HomeDashboardMetrics.classicCardWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                    .fill(HomeDashboardPalette.dashboardCanvas)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                    .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
            )
            .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                .opacity(phase.isIdentity ? 1 : 0.92)
        }
    }
}

struct ClassicTalesSection: View {
    let tales: [ClassicTaleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Klasik Masallar")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .tracking(-0.6)
                    .foregroundStyle(HomeDashboardPalette.ink)

                Text("Sevilen klasik masalları keşfet")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HomeDashboardMetrics.classicCarouselSpacing) {
                    ForEach(tales) { tale in
                        ClassicTaleCard(tale: tale)
                    }
                }
                .padding(.vertical, 8)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 0, for: .scrollContent)

            Text("Bu masallar çocuk gelişimi ve pedagojik değerlere uygun olacak şekilde seçilip yumuşak bir dille düzenlenmiştir; uyku öncesi için sakin ve güvenli bir ton hedeflenir.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }
}

/// Klasik masal kartına basınca açılan tam metin okuma ekranı.
struct ClassicTalePreviewView: View {
    let tale: ClassicTaleItem

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    HomeDashboardPalette.cream,
                    HomeDashboardPalette.creamDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    StoryPhotoCoverView(
                        imageURL: AppConfig.classicTaleCoverImageURL(taleId: tale.id),
                        fallbackTemplate: tale.coverTemplate,
                        title: tale.title,
                        subtitle: nil,
                        tag: tale.tag,
                        showsTextOverlay: false,
                        cornerRadius: StoryCoverMetrics.cornerRadius,
                        width: min(UIScreen.main.bounds.width - 48, 300)
                    )
                    .frame(maxWidth: .infinity)

                    Text(tale.title)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(HomeDashboardPalette.ink)

                    Text(tale.tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(HomeDashboardPalette.accentOrange.opacity(0.15))
                        )

                    Text(tale.fullStory.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(HomeDashboardPalette.ink.opacity(0.92))
                        .lineSpacing(7)

                    Text(tale.attribution)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                        .italic()
                        .padding(.top, 4)

                    NavigationLink {
                        CreateStoryView()
                    } label: {
                        Text("Kendi masalını oluştur")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(HomeDashboardPalette.accentOrange)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Create story card



// MARK: - Recent stories (dashboard styling)

struct DashboardRecentStoriesSection: View {
    let stories: [StoryModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Son Masalların")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .tracking(-0.6)
                    .foregroundStyle(HomeDashboardPalette.ink)

                Text("Kayıtlı masallarına buradan devam et")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
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
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                            .fill(HomeDashboardPalette.dashboardCanvas)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                            .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
                    )
                    .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 10, x: 0, y: 6)
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
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ProgressView()
                                .tint(HomeDashboardPalette.accentOrange)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                LinearGradient(
                    colors: [.white.opacity(0.12), .black.opacity(0.18)],
                    startPoint: .top,
                    endPoint: .bottom
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
            .frame(height: 92)
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
        }
        .padding(14)
        .frame(width: 164, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                .fill(HomeDashboardPalette.dashboardCanvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
        )
        .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 10, x: 0, y: 6)
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
