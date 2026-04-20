import SwiftUI

/// Uzak kapak görseli (Supabase public URL) veya şablon yedeği; metin katmanı isteğe bağlı.
struct StoryPhotoCoverView: View {
    let imageURL: URL?
    let fallbackTemplate: StoryCoverTemplateType
    let title: String
    var subtitle: String?
    var tag: String?
    var showsTextOverlay: Bool
    /// Kapak başlığını alt kenardan hafifçe yukarı alır (ör. ana sayfa klasik masal kartları).
    var titleOverlayExtraBottomInset: CGFloat = 0
    var cornerRadius: CGFloat
    var width: CGFloat

    private var coverHeight: CGFloat { width * StoryCoverMetrics.heightMultiplier }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            ZStack(alignment: .bottomLeading) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                if showsTextOverlay {
                                    StoryCoverBottomScrim()
                                    StoryCoverTitleOverlay(
                                        title: title,
                                        subtitle: subtitle,
                                        tag: tag,
                                        extraBottomInset: titleOverlayExtraBottomInset
                                    )
                                }
                            }
                        case .empty:
                            ZStack {
                                Color.black.opacity(0.06)
                                ProgressView()
                            }
                        case .failure:
                            StoryCoverTemplateView(
                                type: fallbackTemplate,
                                title: title,
                                subtitle: subtitle,
                                tag: tag,
                                showsTextOverlay: showsTextOverlay,
                                titleOverlayExtraBottomInset: titleOverlayExtraBottomInset,
                                cornerRadius: cornerRadius,
                                width: width
                            )
                        @unknown default:
                            StoryCoverTemplateView(
                                type: fallbackTemplate,
                                title: title,
                                subtitle: subtitle,
                                tag: tag,
                                showsTextOverlay: showsTextOverlay,
                                titleOverlayExtraBottomInset: titleOverlayExtraBottomInset,
                                cornerRadius: cornerRadius,
                                width: width
                            )
                        }
                    }
                } else {
                    StoryCoverTemplateView(
                        type: fallbackTemplate,
                        title: title,
                        subtitle: subtitle,
                        tag: tag,
                        showsTextOverlay: showsTextOverlay,
                        titleOverlayExtraBottomInset: titleOverlayExtraBottomInset,
                        cornerRadius: cornerRadius,
                        width: width
                    )
                }
            }
            .frame(width: width, height: coverHeight)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
