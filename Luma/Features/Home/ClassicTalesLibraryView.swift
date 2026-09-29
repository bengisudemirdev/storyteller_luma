import SwiftUI

/// Tüm klasik masalların listelendiği kütüphane ekranı (ana sayfadaki “Tümünü Gör” hedefi).
struct ClassicTalesLibraryView: View {
    let tales: [ClassicTaleItem]

    var body: some View {
        ZStack {
            HomeMagicalScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(tales) { tale in
                        NavigationLink {
                            ClassicTalePreviewView(tale: tale)
                        } label: {
                            ClassicTaleLibraryRow(tale: tale)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Klasik Masallar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ClassicTaleLibraryRow: View {
    let tale: ClassicTaleItem

    private var classicCoverURL: URL? {
        tale.resolvedCoverImageURL
    }

    private var rowThumbShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 18,
                bottomLeading: 12,
                bottomTrailing: 12,
                topTrailing: 18
            ),
            style: .continuous
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            StoryPhotoCoverView(
                imageURL: classicCoverURL,
                fallbackTemplate: tale.coverTemplate,
                title: tale.title,
                subtitle: nil,
                tag: tale.tag,
                // Başlık ve etiket satırın yanında zaten yazıyor; 88 pt'lik küçük kapağın üstüne bindirilince yazılar
                // taşıyor ("NAZİK ANLATI M", "Külkedi/si") ve başlık iki kez görünüyordu.
                showsTextOverlay: false,
                cornerRadius: 18,
                width: 88
            )
            .clipShape(rowThumbShape)
            .overlay {
                if classicCoverURL == nil {
                    rowThumbShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.06),
                                    Color.black.opacity(0.28)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(tale.title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(tale.teaser)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Text(tale.tag)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.95))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(HomeDashboardPalette.accentOrange.opacity(0.12))
                    )
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeDashboardPalette.muted.opacity(0.65))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                .fill(HomeDashboardPalette.dashboardCanvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
        )
        .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 8, x: 0, y: 4)
    }
}
