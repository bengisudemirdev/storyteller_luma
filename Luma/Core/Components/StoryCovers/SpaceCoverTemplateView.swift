import SwiftUI

/// Uzay: yumuşak galaksi, gezegenler, meraklı keşif.
struct SpaceCoverTemplateView: View {
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
                    Color(hex: "3D2F55"),
                    Color(hex: "2A2548"),
                    Color(hex: "1E1C38")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Nebula yumuşak lekeleri
            Circle()
                .fill(Color(hex: "7B6B9E").opacity(0.35))
                .frame(width: width * 0.7, height: width * 0.7)
                .offset(x: -width * 0.2, y: -width * 0.25)
                .blur(radius: 25)

            Circle()
                .fill(Color(hex: "5A4A78").opacity(0.3))
                .frame(width: width * 0.55, height: width * 0.55)
                .offset(x: width * 0.25, y: width * 0.1)
                .blur(radius: 20)

            // Gezegenler
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F0D090").opacity(0.9), Color(hex: "D4A860")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                .offset(x: -width * 0.28, y: -width * 0.32)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "E8A8C8").opacity(0.75), Color(hex: "B878A8").opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: 16)
                .offset(x: width * 0.32, y: -width * 0.2)

            Ellipse()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 36, height: 12)
                .rotationEffect(.degrees(-20))
                .offset(x: width * 0.32, y: -width * 0.2)

            // Minik roket
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "E8E0F0"), Color(hex: "B8A8C8")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 14, height: 36)
                TriangleUp()
                    .fill(Color(hex: "F0B8A8"))
                    .frame(width: 16, height: 14)
                    .offset(y: -22)
                Circle()
                    .fill(Color(hex: "F0D878").opacity(0.85))
                    .frame(width: 10, height: 10)
                    .offset(y: 20)
                    .blur(radius: 3)
            }
            .offset(x: width * 0.08, y: -width * 0.02)
            .rotationEffect(.degrees(-28))

            SpaceStarsLayer(width: width)

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

private struct SpaceStarsLayer: View {
    let width: CGFloat

    var body: some View {
        ForEach(0..<14, id: \.self) { i in
            Circle()
                .fill(Color.white.opacity(Double([0.35, 0.55, 0.45, 0.65, 0.4, 0.5, 0.6, 0.35, 0.5, 0.45, 0.55, 0.4, 0.5, 0.48][i % 14])))
                .frame(width: CGFloat([1.5, 2, 1, 2.5, 1.5, 2, 1.2, 2, 1.8, 1, 2.2, 1.5, 2, 1.3][i % 14]),
                       height: CGFloat([1.5, 2, 1, 2.5, 1.5, 2, 1.2, 2, 1.8, 1, 2.2, 1.5, 2, 1.3][i % 14]))
                .position(
                    x: width * CGFloat([0.15, 0.85, 0.45, 0.72, 0.25, 0.92, 0.55, 0.38, 0.68, 0.12, 0.78, 0.5, 0.22, 0.65][i % 14]),
                    y: width * CGFloat([0.18, 0.25, 0.12, 0.38, 0.45, 0.2, 0.32, 0.5, 0.15, 0.42, 0.28, 0.22, 0.35, 0.48][i % 14])
                )
        }
    }
}

private struct TriangleUp: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
