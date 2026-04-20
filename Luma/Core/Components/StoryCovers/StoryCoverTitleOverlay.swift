import SwiftUI

/// Tüm şablonlarda tutarlı başlık / alt başlık / etiket katmanı.
struct StoryCoverTitleOverlay: View {
    let title: String
    var subtitle: String?
    var tag: String?
    /// Üst veya alt yerleşim
    var position: TitlePosition = .bottom
    /// Başlık grubunu alttan biraz yukarı taşır (kapak alt kenarından ek boşluk).
    var extraBottomInset: CGFloat = 0

    enum TitlePosition {
        case top
        case bottom
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if position == .bottom { Spacer(minLength: 0) }

            if let tag, !tag.isEmpty {
                Text(tag.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.22))
                    )
            }

            Text(title)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
            }

            if position == .top { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position == .top ? .topLeading : .bottomLeading)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 14 + extraBottomInset)
    }
}

/// Okunabilirlik için alt bant (isteğe bağlı).
struct StoryCoverBottomScrim: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(0.35)
            ],
            startPoint: .center,
            endPoint: .bottom
        )
    }
}
