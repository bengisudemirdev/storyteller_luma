import SwiftUI

// MARK: - Design tokens (warm bedtime dashboard)

enum HomeDashboardPalette {
    static let cream = Color(hex: "FAF6EF")
    static let creamDeep = Color(hex: "F3EBE0")
    static let nightTop = Color(hex: "2D2640")
    static let nightMid = Color(hex: "4A3F6B")
    static let nightBottom = Color(hex: "6B5B8C")
    static let moonGlow = Color(hex: "FFF8E7")
    static let accentOrange = Color(hex: "E8956A")
    static let accentOrangeSoft = Color(hex: "F4B08C")
    static let starTint = Color.white.opacity(0.92)
    static let heroTitle = Color.white
    static let heroSubtitle = Color.white.opacity(0.88)
    static let ink = Color(hex: "2C2A32")
    static let muted = Color(hex: "6B6560")
    static let cardSurface = Color.white
    static let cardShadow = Color.black.opacity(0.07)
}

enum HomeDashboardMetrics {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 28
    static let heroCornerRadius: CGFloat = 28
    static let cardCornerRadius: CGFloat = 20
    static let classicCardWidth: CGFloat = 168
    /// Kart içi yatay padding 12+12; kapak genişliği.
    static let classicCoverInnerWidth: CGFloat = classicCardWidth - 24
}

// MARK: - Shared screen chrome (Home, Profil, Masal oluştur)

/// Ana sayfa ile aynı sıcak krem geçişli arka plan.
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

/// Gece gökyüzü hero kartının ay, bulut ve yıldız süslemesi.
struct DashboardHeroNightDecor: View {
    var body: some View {
        ZStack {
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
                        HomeDashboardPalette.accentOrange.opacity(0.18),
                        HomeDashboardPalette.accentOrangeSoft.opacity(0.12)
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
                            HomeDashboardPalette.nightTop,
                            HomeDashboardPalette.nightMid,
                            HomeDashboardPalette.nightBottom
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(DashboardHeroNightDecor())
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 20, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(HomeDashboardPalette.heroTitle)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.heroSubtitle)
                        .fixedSize(horizontal: false, vertical: true)

                    if let caption, !caption.isEmpty {
                        Text(caption)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
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
    var body: some View {
        DashboardNightHeroLayout(
            title: "Haydi Masal Diyarı’na Yolculuk",
            subtitle: AppBrand.subtitle,
            caption: "Bu gece birlikte güzel bir masal seçelim.",
            footer: {
                NavigationLink {
                    CreateStoryView()
                } label: {
                    HStack(spacing: 8) {
                        Text("Bu Geceki Masalı Seç")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(HomeDashboardPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        HomeDashboardPalette.moonGlow,
                                        HomeDashboardPalette.accentOrangeSoft.opacity(0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: HomeDashboardPalette.accentOrange.opacity(0.35), radius: 12, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
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

    var body: some View {
        NavigationLink {
            ClassicTalePreviewView(tale: tale)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                StoryCoverTemplateView(
                    type: tale.coverTemplate,
                    title: tale.title,
                    subtitle: nil,
                    tag: tale.tag,
                    showsTextOverlay: true,
                    cornerRadius: 16,
                    width: HomeDashboardMetrics.classicCoverInnerWidth
                )

                Text(tale.teaser)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(width: HomeDashboardMetrics.classicCardWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                    .fill(HomeDashboardPalette.cardSurface)
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ClassicTalesSection: View {
    let tales: [ClassicTaleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Klasik Masallar")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)

                Text("Sevilen klasik masalları keşfet")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(tales) { tale in
                        ClassicTaleCard(tale: tale)
                    }
                }
                .padding(.vertical, 6)
                .padding(.trailing, 4)
            }

            Text("Bu masallar çocuk gelişimi ve pedagojik değerlere uygun olacak şekilde seçilip yumuşak bir dille düzenlenmiştir; uyku öncesi için sakin ve güvenli bir ton hedeflenir.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
                .padding(.top, 6)
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
                    StoryCoverTemplateView(
                        type: tale.coverTemplate,
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Son Masalların")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)

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
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HomeDashboardPalette.ink)
                            Text("İlk masalını oluştur ve buradan tekrar oku.")
                                .font(.caption)
                                .foregroundStyle(HomeDashboardPalette.muted)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .fill(HomeDashboardPalette.cardSurface)
                            .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
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
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct DashboardRecentStoryCard: View {
    let story: StoryModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            HomeDashboardPalette.accentOrange.opacity(0.2),
                            HomeDashboardPalette.accentOrangeSoft.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 88)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.85))
                )

            Text(story.title)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
                .lineLimit(2)

            if let date = story.created_at {
                Text(Self.dateFormatter.string(from: date))
                    .font(.caption2)
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
        }
        .padding(12)
        .frame(width: 152, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 4)
        )
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    }()
}
