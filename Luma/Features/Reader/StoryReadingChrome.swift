import SwiftUI

/// Paylaşılan masal okuma düzeni: sıcak zemin, kart ve tipografi (`StoryReaderView`, klasik masal önizlemesi).
enum StoryReadingChrome {
    static let horizontalPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 22
    static let titleSize: CGFloat = 24
    static let bodySize: CGFloat = 17
    static let bodyLineSpacing: CGFloat = 7
    /// Metin sütunu (iPad’de çok geniş kırpılmasın diye üst sınır).
    static let contentMaxWidth: CGFloat = 540
    /// İç padding (22×2) + metin alanı üst sınırı.
    static var cardMaxOuterWidth: CGFloat { contentMaxWidth + 44 }
}

// MARK: - Sayfalama (gerçek metin yüksekliğine göre)

/// Metnin gerçek yüksekliğini ölçmek için ekrandaki yazı tipiyle birebir aynı UIKit yazı tipleri.
enum StoryTextMetrics {
    static func roundedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    static func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.serif) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    static var bodyFont: UIFont { serifFont(size: StoryReadingChrome.bodySize, weight: .regular) }
    static var titleFont: UIFont { serifFont(size: StoryReadingChrome.titleSize, weight: .bold) }

    static func height(of text: String, width: CGFloat, font: UIFont, lineSpacing: CGFloat) -> CGFloat {
        guard !text.isEmpty, width > 1 else { return 0 }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: style],
            context: nil
        )
        return ceil(rect.height)
    }

    static func bodyHeight(_ text: String, width: CGFloat) -> CGFloat {
        height(of: text, width: width, font: bodyFont, lineSpacing: StoryReadingChrome.bodyLineSpacing)
    }

    static func titleHeight(_ text: String, width: CGFloat) -> CGFloat {
        height(of: text, width: width, font: titleFont, lineSpacing: 0)
    }
}

enum StoryReadingPagination {
    /// Paragraflar arası boşluk (metin içinde boş satır yerine gerçek aralık).
    static let paragraphSpacing: CGFloat = 14
    /// SwiftUI ile UIKit ölçümü arasındaki küçük farklara karşı güvenlik payı.
    private static let safety: CGFloat = 0.975

    /// Metni paragraflara ayırır. Boş satır yoksa tek satır sonlarına, o da yoksa uzun bloğu cümle gruplarına bölünür.
    static func paragraphs(from text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var parts = trimmed.components(separatedBy: "\n\n")
        if parts.count == 1 { parts = trimmed.components(separatedBy: "\n") }
        parts = parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Tek koca blok geldiyse okunaklı olsun diye yaklaşık 450 karakterlik cümle gruplarına böl.
        if parts.count == 1, let only = parts.first, only.count > 700 {
            return groupSentences(sentences(of: only), maxChars: 450)
        }
        return parts
    }

    static func sentences(of text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { sub, _, _, _ in
            if let sub {
                let t = sub.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { result.append(t) }
            }
        }
        return result.isEmpty ? [text] : result
    }

    private static func groupSentences(_ sentences: [String], maxChars: Int) -> [String] {
        var groups: [String] = []
        var current = ""
        for sentence in sentences {
            if !current.isEmpty, current.count + 1 + sentence.count > maxChars {
                groups.append(current)
                current = sentence
            } else {
                current = current.isEmpty ? sentence : current + " " + sentence
            }
        }
        if !current.isEmpty { groups.append(current) }
        return groups
    }

    /// Metni, verilen sayfa yüksekliklerine göre sayfalara böler. Her sayfa dolana kadar metin akar; sığmayan
    /// paragraf kelime sınırından bölünüp sonraki sayfada devam eder (sayfa altında boşluk kalmaz).
    /// - Parameters:
    ///   - textWidth: Metnin çizileceği gerçek genişlik.
    ///   - firstPageHeight: İlk sayfada metne ayrılan yükseklik (başlık/kapak düşülmüş).
    ///   - otherPageHeight: Diğer sayfalarda metne ayrılan yükseklik.
    static func pages(
        from storyContent: String,
        textWidth: CGFloat,
        firstPageHeight: CGFloat,
        otherPageHeight: CGFloat
    ) -> [[String]] {
        let paras = paragraphs(from: storyContent)
        guard !paras.isEmpty else { return [[""]] }

        let minUseful = StoryTextMetrics.bodyHeight("Ag", width: textWidth) * 3
        func capacity(_ pageIndex: Int) -> CGFloat {
            max(minUseful, (pageIndex == 0 ? firstPageHeight : otherPageHeight) * safety)
        }

        var pages: [[String]] = [[]]
        var used: CGFloat = 0

        func startNewPage() {
            pages.append([])
            used = 0
        }

        func gapIfNeeded() -> CGFloat { pages[pages.count - 1].isEmpty ? 0 : paragraphSpacing }

        for paragraph in paras {
            var remaining = [paragraph]
            // Tek paragraf en fazla birkaç kez bölünür; sonsuz döngüye karşı üst sınır.
            var guardCount = 0
            while let current = remaining.first, guardCount < 40 {
                guardCount += 1
                let pageIndex = pages.count - 1
                let height = StoryTextMetrics.bodyHeight(current, width: textWidth)
                let gap = gapIfNeeded()

                if used + gap + height <= capacity(pageIndex) {
                    pages[pageIndex].append(current)
                    used += gap + height
                    remaining.removeFirst()
                    continue
                }

                // Sığmadı: sayfayı kelime kelime doldur (ikili arama); kalan metin sonraki sayfada devam eder.
                let words = current.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
                let room = capacity(pageIndex)
                func fits(_ count: Int) -> Bool {
                    used + gap + StoryTextMetrics.bodyHeight(words.prefix(count).joined(separator: " "), width: textWidth) <= room
                }
                var low = 0
                var high = words.count
                while low < high {
                    let mid = (low + high + 1) / 2
                    if fits(mid) { low = mid } else { high = mid - 1 }
                }

                if low == 0 {
                    if pages[pageIndex].isEmpty {
                        // Sayfa boş ve tek kelime bile sığmıyor: yine de yerleştir (kaydırma yedek olarak kalır).
                        let first = words.first ?? current
                        pages[pageIndex].append(first)
                        used += StoryTextMetrics.bodyHeight(first, width: textWidth)
                        let rest = words.dropFirst().joined(separator: " ")
                        remaining = rest.isEmpty ? [] : [rest]
                        if !remaining.isEmpty { startNewPage() }
                    } else {
                        startNewPage()
                    }
                } else {
                    let fit = words.prefix(low).joined(separator: " ")
                    pages[pageIndex].append(fit)
                    let rest = words.dropFirst(low).joined(separator: " ")
                    remaining = rest.isEmpty ? [] : [rest]
                    if !remaining.isEmpty { startNewPage() }
                }
            }
        }

        var result = pages.filter { !$0.isEmpty }

        // Son sayfada çok az metin kalırsa (yetim), sığıyorsa öncekiyle birleştir.
        if result.count >= 2, let last = result.last {
            let lastHeight = last.reduce(0) { $0 + StoryTextMetrics.bodyHeight($1, width: textWidth) }
                + CGFloat(max(last.count - 1, 0)) * paragraphSpacing
            let prevIndex = result.count - 2
            let prevHeight = result[prevIndex].reduce(0) { $0 + StoryTextMetrics.bodyHeight($1, width: textWidth) }
                + CGFloat(max(result[prevIndex].count - 1, 0)) * paragraphSpacing
            if lastHeight < minUseful, prevHeight + paragraphSpacing + lastHeight <= capacity(prevIndex) {
                result[prevIndex].append(contentsOf: last)
                result.removeLast()
            }
        }
        return result.isEmpty ? [[storyContent]] : result
    }

    /// Ölçüm henüz yapılamadıysa (ilk çizim) kullanılan basit yedek sayfalama.
    static func fallbackPages(from storyContent: String) -> [[String]] {
        let paras = paragraphs(from: storyContent)
        return [paras.isEmpty ? [storyContent] : paras]
    }
}

/// Sayfadaki paragraflar: boş satır yerine gerçek paragraf aralığı.
struct StoryPageBody: View {
    let paragraphs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: StoryReadingPagination.paragraphSpacing) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .storyReadingBodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Okuma ekranı renkleri: lamba ışığında kâğıt hissi (sıcak krem + kahverengi mürekkep).
enum StoryReadingPalette {
    static let paperTop = Color(hex: "FFFBF2")
    static let paperBottom = Color(hex: "FBF0DC")
    static let paperEdge = Color(hex: "E9D7B8")
    static let ink = Color(hex: "3A2E27")
    static let accent = Color(hex: "C8743F")
}

struct StoryReadingWarmBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F6E7CF"), Color(hex: "EFDDBF"), Color(hex: "E8D1AE")],
                startPoint: .top,
                endPoint: .bottom
            )
            // Lamba ışığı: üstten yumuşak sıcak parıltı.
            RadialGradient(
                colors: [Color(hex: "FFE9C2").opacity(0.75), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

/// Kâğıt dokulu sayfa zemini: sıcak degrade, ince kenar ve iç gölge ile kitap sayfası görünümü.
struct StoryPaperBackground: View {
    var cornerRadius: CGFloat = StoryReadingChrome.cardCornerRadius

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [StoryReadingPalette.paperTop, StoryReadingPalette.paperBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(StoryReadingPalette.paperEdge, lineWidth: 1)
            )
            .overlay(
                // Sayfa kıvrımı hissi: kenarlarda hafif iç gölge.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color(hex: "B9894F").opacity(0.10), lineWidth: 6)
                    .blur(radius: 5)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .shadow(color: Color(hex: "6B4A24").opacity(0.22), radius: 16, x: 0, y: 10)
    }
}

/// Başlık altı süs çizgisi.
struct StoryOrnamentDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Capsule().fill(StoryReadingPalette.accent.opacity(0.35)).frame(width: 34, height: 1.5)
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(StoryReadingPalette.accent.opacity(0.8))
            Capsule().fill(StoryReadingPalette.accent.opacity(0.35)).frame(width: 34, height: 1.5)
        }
        .accessibilityHidden(true)
    }
}

/// Okuyucu / karusel altı için sayfa noktaları (turuncu vurgu).
struct StoryReadingPageDots: View {
    let currentIndex: Int
    let pageCount: Int

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(
                            index == currentIndex
                                ? HomeDashboardPalette.accentOrange
                                : HomeDashboardPalette.sectionCaption.opacity(0.38)
                        )
                        .frame(width: index == currentIndex ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: currentIndex)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sayfa \(currentIndex + 1) / \(pageCount)")
    }
}

/// Önceki / sonraki düğmeleri + sayfa etiketi + noktalar.
struct StoryReadingPageControls: View {
    @Binding var currentPage: Int
    let pageCount: Int

    private var canBack: Bool { currentPage > 0 }
    private var canForward: Bool { currentPage < pageCount - 1 }

    var body: some View {
        VStack(spacing: 0) {
            if pageCount > 1 {
                HStack(alignment: .center, spacing: 10) {
                    pageStepButton(
                        systemName: "chevron.left",
                        enabled: canBack,
                        label: String(localized: "Önceki sayfa")
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            currentPage = max(0, currentPage - 1)
                        }
                    }

                    VStack(spacing: 6) {
                        Text("Sayfa \(currentPage + 1) / \(pageCount)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink)

                        StoryReadingPageDots(currentIndex: currentPage, pageCount: pageCount)
                    }
                    .frame(minWidth: 100)

                    pageStepButton(
                        systemName: "chevron.right",
                        enabled: canForward,
                        label: String(localized: "Sonraki sayfa")
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            currentPage = min(pageCount - 1, currentPage + 1)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "FFF6E6").opacity(0.95))
                        .shadow(color: Color(hex: "6B4A24").opacity(0.14), radius: 6, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(StoryReadingPalette.paperEdge, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, StoryReadingChrome.horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 22)
    }

    private func pageStepButton(
        systemName: String,
        enabled: Bool,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(enabled ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.sectionCaption.opacity(0.35))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(enabled ? HomeDashboardPalette.accentOrange.opacity(0.12) : HomeDashboardPalette.sectionCaption.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

struct StoryReadingTextCard<Content: View>: View {
    var minHeight: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background(StoryPaperBackground())
    }
}

extension View {
    /// Masal gövdesi: okunabilir rounded + rahat satır aralığı.
    func storyReadingBodyStyle() -> some View {
        self
            .font(.system(size: StoryReadingChrome.bodySize, weight: .regular, design: .serif))
            .foregroundStyle(StoryReadingPalette.ink)
            .lineSpacing(StoryReadingChrome.bodyLineSpacing)
    }
}
