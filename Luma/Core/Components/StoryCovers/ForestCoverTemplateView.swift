import SwiftUI

/// Orman macerası: ağaçlar, yol, sıcak ışık.
struct ForestCoverTemplateView: View {
    let title: String
    var subtitle: String?
    var tag: String?
    var showsTextOverlay: Bool = true
    var cornerRadius: CGFloat
    var width: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "D4C4A8"),
                    Color(hex: "9DB89A"),
                    Color(hex: "6E8B72")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Arka ağaç siluetleri
            ForestTreeSilhouette()
                .fill(Color(hex: "5A7A5E").opacity(0.35))
                .frame(width: width * 0.35, height: width * 0.85)
                .offset(x: -width * 0.28, y: width * 0.12)

            ForestTreeSilhouette()
                .fill(Color(hex: "4D6B52").opacity(0.4))
                .frame(width: width * 0.42, height: width * 0.95)
                .offset(x: width * 0.32, y: width * 0.08)

            // Yol
            Path { path in
                let mid = width * 0.5
                path.move(to: CGPoint(x: mid - width * 0.12, y: width * 1.15))
                path.addQuadCurve(
                    to: CGPoint(x: mid + width * 0.08, y: width * 0.55),
                    control: CGPoint(x: mid, y: width * 0.85)
                )
                path.addLine(to: CGPoint(x: mid + width * 0.22, y: width * 1.15))
                path.addLine(to: CGPoint(x: mid - width * 0.12, y: width * 1.15))
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "C4B59A").opacity(0.55),
                        Color(hex: "A08F72").opacity(0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Altın ışık
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "F0D9A8").opacity(0.55),
                            Color(hex: "E8C080").opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: width * 0.45
                    )
                )
                .frame(width: width * 0.9, height: width * 0.9)
                .offset(y: -width * 0.05)

            // Yaprak parçacıkları
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "B8D4A8").opacity(0.35))
                    .frame(width: 6, height: 6)
                    .offset(
                        x: CGFloat([-30, 40, -50, 60, 10][i]),
                        y: CGFloat([-80, -100, -60, -90, -120][i])
                    )
            }

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
                    position: .bottom
                )
            }
        }
        .storyCoverFrame(width: width, cornerRadius: cornerRadius)
    }
}

private struct ForestTreeSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.9, y: h * 0.72))
        p.addLine(to: CGPoint(x: w * 0.58, y: h * 0.72))
        p.addLine(to: CGPoint(x: w * 0.58, y: h))
        p.addLine(to: CGPoint(x: w * 0.42, y: h))
        p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
        p.addLine(to: CGPoint(x: w * 0.1, y: h * 0.72))
        p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.15, y: h * 0.42))
        p.closeSubpath()
        return p
    }
}
