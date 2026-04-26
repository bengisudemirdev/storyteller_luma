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
                    CachedRemoteImage(url: imageURL) { image in
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
                    } placeholder: {
                        if showsTextOverlay {
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
                        } else {
                            ZStack {
                                Color.black.opacity(0.06)
                                ProgressView()
                            }
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
