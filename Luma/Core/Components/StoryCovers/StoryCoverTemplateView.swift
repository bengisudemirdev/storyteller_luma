import SwiftUI

/// Şablona göre doğru kapak görünümünü üreten üst bileşen.
struct StoryCoverTemplateView: View {
    let type: StoryCoverTemplateType
    let title: String
    var subtitle: String?
    var tag: String?
    /// Kapak illüstrasyonu; başlık ayrı ekranda gösterilecekse `false`.
    var showsTextOverlay: Bool = true
    var cornerRadius: CGFloat = StoryCoverMetrics.cornerRadius
    var width: CGFloat = StoryCoverMetrics.defaultWidth

    var body: some View {
        Group {
            switch type {
            case .sleep:
                SleepCoverTemplateView(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    showsTextOverlay: showsTextOverlay,
                    cornerRadius: cornerRadius,
                    width: width
                )
            case .forest:
                ForestCoverTemplateView(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    showsTextOverlay: showsTextOverlay,
                    cornerRadius: cornerRadius,
                    width: width
                )
            case .castle:
                CastleCoverTemplateView(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    showsTextOverlay: showsTextOverlay,
                    cornerRadius: cornerRadius,
                    width: width
                )
            case .friendship:
                FriendshipCoverTemplateView(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    showsTextOverlay: showsTextOverlay,
                    cornerRadius: cornerRadius,
                    width: width
                )
            case .space:
                SpaceCoverTemplateView(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    showsTextOverlay: showsTextOverlay,
                    cornerRadius: cornerRadius,
                    width: width
                )
            case .ocean:
                OceanCoverTemplateView(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    showsTextOverlay: showsTextOverlay,
                    cornerRadius: cornerRadius,
                    width: width
                )
            }
        }
    }
}

#Preview("Wrapper — Sleep") {
    StoryCoverTemplateView(
        type: .sleep,
        title: "Ay Dede’nin Uykulu Bahçesi",
        subtitle: "Sakin bir gece masalı",
        tag: "Uyku öncesi"
    )
    .padding()
    .background(Color(hex: "F5EDE4"))
}
