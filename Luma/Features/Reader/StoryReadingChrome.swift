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

// MARK: - Sayfalama (tek ekranda okuma için kısa sayfalar)

enum StoryReadingPagination {
    /// İlk sayfada başlık için gövdeye biraz daha az; sonraki sayfalar daha uzun olabilir.
    static func pages(from storyContent: String, firstPageBudget: Int = 520, otherPageBudget: Int = 900) -> [String] {
        let trimmed = storyContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [""] }

        let maxPiece = min(firstPageBudget, otherPageBudget)
        let chunks = chunkText(trimmed, maxChunk: max(120, maxPiece))

        var pages: [String] = []
        var current = ""
        var isFirstPage = true

        for ch in chunks {
            let budget = isFirstPage ? firstPageBudget : otherPageBudget
            let candidate = current.isEmpty ? ch : current + "\n\n" + ch
            if candidate.count <= budget {
                current = candidate
            } else {
                if !current.isEmpty {
                    pages.append(current)
                }
                current = ch
                isFirstPage = false
            }
        }

        if !current.isEmpty {
            pages.append(current)
        }

        return pages.isEmpty ? [trimmed] : pages
    }

    private struct PrefixTake {
        let text: String
        let remainder: String
    }

    /// Kelime sınırına yakın keser; `maxLen` karakteri aşmamaya çalışır.
    private static func takePrefix(upTo maxLen: Int, from text: String) -> PrefixTake {
        guard text.count > maxLen else { return PrefixTake(text: text, remainder: "") }
        let idx = text.index(text.startIndex, offsetBy: maxLen)
        var cut = String(text[..<idx])
        if let lastSpace = cut.lastIndex(of: " "), lastSpace > cut.startIndex {
            cut = String(text[..<lastSpace])
        }
        if cut.isEmpty {
            cut = String(text.prefix(maxLen))
        }
        let rest = String(text[cut.endIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return PrefixTake(text: cut.trimmingCharacters(in: .whitespacesAndNewlines), remainder: rest)
    }

    private static func chunkText(_ text: String, maxChunk: Int) -> [String] {
        var chunks: [String] = []
        for para in text.components(separatedBy: "\n\n") {
            let p = para.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !p.isEmpty else { continue }
            if p.count <= maxChunk {
                chunks.append(p)
            } else {
                var rest = p
                while !rest.isEmpty {
                    let t = takePrefix(upTo: maxChunk, from: rest)
                    if !t.text.isEmpty { chunks.append(t.text) }
                    rest = t.remainder
                }
            }
        }
        return chunks
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
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
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
