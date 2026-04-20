import SwiftUI

/// Klasik peri masalı: şato ve rüya gökyüzü.
struct CastleCoverTemplateView: View {
    let title: String
    var subtitle: String?
    var tag: String?
    var showsTextOverlay: Bool = true
    var titleOverlayExtraBottomInset: CGFloat = 0
    var cornerRadius: CGFloat
    var width: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "F0E4EC"),
                    Color(hex: "D8C8E8"),
                    Color(hex: "B8A8D4")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<8, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat([2, 2.5, 2, 3, 2, 2.5, 2, 2][i])))
                    .foregroundStyle(Color.white.opacity(Double([0.5, 0.65, 0.45, 0.7, 0.55, 0.5, 0.6, 0.45][i])))
                    .position(
                        x: width * CGFloat([0.2, 0.75, 0.5, 0.88, 0.12, 0.65, 0.38, 0.92][i]),
                        y: width * CGFloat([0.25, 0.2, 0.15, 0.35, 0.4, 0.32, 0.22, 0.28][i])
                    )
            }

            CastleBlockView()
                .frame(width: width * 0.68, height: width * 0.52)
                .offset(y: width * 0.14)
                .shadow(color: Color(hex: "9A7AB0").opacity(0.22), radius: 14, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "E8D0A8").opacity(0.55),
                            Color(hex: "F5E6C8").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(width * 0.07)
                .allowsHitTesting(false)

            if showsTextOverlay {
                VStack {
                    Spacer()
                    StoryCoverBottomScrim()
                        .frame(height: width * 0.55)
                }

                StoryCoverTitleOverlay(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    position: .bottom,
                    extraBottomInset: titleOverlayExtraBottomInset
                )
            }
        }
        .storyCoverFrame(width: width, cornerRadius: cornerRadius)
    }
}

private struct CastleBlockView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            CastleTower(narrow: true)
            CastleTower(narrow: false)
            CastleTower(narrow: true)
        }
    }
}

private struct CastleTower: View {
    var narrow: Bool

    var body: some View {
        VStack(spacing: 0) {
            CastleRoof()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F2E0F5"), Color(hex: "D4C0E4")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: narrow ? 36 : 48, height: narrow ? 22 : 30)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "EDE4F5").opacity(0.98), Color(hex: "C8B4DC").opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: narrow ? 40 : 54, height: narrow ? 62 : 86)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
    }
}

private struct CastleRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
