import SwiftUI

/// Paylaşılan masal okuma düzeni: sıcak zemin, kart ve tipografi (`StoryReaderView`, klasik masal önizlemesi).
enum StoryReadingChrome {
    static let horizontalPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 22
    static let titleSize: CGFloat = 24
    static let bodySize: CGFloat = 16
    static let bodyLineSpacing: CGFloat = 8
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

    static var bodyFont: UIFont { roundedFont(size: StoryReadingChrome.bodySize, weight: .regular) }
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
    private static let safety: CGFloat = 0.94

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

    /// Metni, verilen sayfa yüksekliklerine göre sayfalara böler. Paragraf sınırlarını korur; sığmayan paragrafı
    /// CÜMLE sınırından bölerek sonraki sayfaya devam ettirir (cümle ortasında kesmez).
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

                // Sığmadı: cümle cümle doldur.
                let sents = sentences(of: current)
                var fit = ""
                var consumed = 0
                for sentence in sents {
                    let candidate = fit.isEmpty ? sentence : fit + " " + sentence
                    if used + gap + StoryTextMetrics.bodyHeight(candidate, width: textWidth) <= capacity(pageIndex) {
                        fit = candidate
                        consumed += 1
                    } else {
                        break
                    }
                }

                if fit.isEmpty {
                    if pages[pageIndex].isEmpty {
                        // Sayfa boş ve tek cümle bile sığmıyor: cümleyi zorla yerleştir (kaydırma yedek olarak kalır).
                        pages[pageIndex].append(sents.first ?? current)
                        used += StoryTextMetrics.bodyHeight(sents.first ?? current, width: textWidth)
                        let rest = sents.dropFirst().joined(separator: " ")
                        remaining = rest.isEmpty ? [] : [rest]
                        if !remaining.isEmpty { startNewPage() }
                    } else {
                        startNewPage()
                    }
                } else {
                    pages[pageIndex].append(fit)
                    let rest = sents.dropFirst(consumed).joined(separator: " ")
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

struct StoryReadingWarmBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                HomeDashboardPalette.cream,
                HomeDashboardPalette.creamDeep,
                Color(hex: "F7EFE4")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
                        .fill(HomeDashboardPalette.cardSurface.opacity(0.97))
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 6, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HomeDashboardPalette.accentOrange.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, StoryReadingChrome.horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .background(
            LinearGradient(
                colors: [
                    HomeDashboardPalette.creamDeep.opacity(0.22),
                    HomeDashboardPalette.cream.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
            .background(
                RoundedRectangle(cornerRadius: StoryReadingChrome.cardCornerRadius, style: .continuous)
                    .fill(HomeDashboardPalette.dashboardCanvas)
                    .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 14, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StoryReadingChrome.cardCornerRadius, style: .continuous)
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
    }
}

extension View {
    /// Masal gövdesi: okunabilir rounded + rahat satır aralığı.
    func storyReadingBodyStyle() -> some View {
        self
            .font(.system(size: StoryReadingChrome.bodySize, weight: .regular, design: .rounded))
            .foregroundStyle(HomeDashboardPalette.ink.opacity(0.92))
            .lineSpacing(StoryReadingChrome.bodyLineSpacing)
    }
}
