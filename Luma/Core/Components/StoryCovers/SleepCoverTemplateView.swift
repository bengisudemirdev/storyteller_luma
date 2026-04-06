import SwiftUI

/// Uyku / gece teması: ay, bulutlar, yıldızlar.
struct SleepCoverTemplateView: View {
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
                    Color(hex: "E8DCC8"),
                    Color(hex: "C5D4E0"),
                    Color(hex: "8FA4BC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Yumuşak bulutlar
            CloudPuff()
                .fill(Color.white.opacity(0.35))
                .frame(width: width * 0.55, height: width * 0.2)
                .offset(x: -width * 0.12, y: -width * 0.15)
                .blur(radius: 1)

            CloudPuff()
                .fill(Color.white.opacity(0.22))
                .frame(width: width * 0.45, height: width * 0.16)
                .offset(x: width * 0.2, y: -width * 0.22)
                .blur(radius: 2)

            // Ay
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFF8E7"),
                            Color(hex: "F5E6C8").opacity(0.9),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 42
                    )
                )
                .frame(width: 72, height: 72)
                .offset(x: width * 0.28, y: -width * 0.28)

            // Altın sıcaklık halesi
            Circle()
                .fill(Color(hex: "E8C9A0").opacity(0.25))
                .frame(width: width * 0.9, height: width * 0.9)
                .offset(y: width * 0.35)
                .blur(radius: 28)

            SleepStarsLayer(width: width)

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

private struct SleepStarsLayer: View {
    let width: CGFloat

    private let offsets: [(CGFloat, CGFloat, CGFloat)] = [
        (-0.32, -0.38, 2.5), (0.15, -0.42, 2), (0.38, -0.35, 2.2),
        (-0.25, -0.15, 1.8), (0.08, -0.2, 2), (0.32, -0.12, 1.6)
    ]

    var body: some View {
        ForEach(0..<offsets.count, id: \.self) { i in
            let o = offsets[i]
            Image(systemName: "sparkle")
                .font(.system(size: o.2))
                .foregroundStyle(Color.white.opacity(0.75))
                .position(
                    x: width * 0.5 + width * o.0,
                    y: width * 0.5 + width * o.1
                )
        }
    }
}

private struct CloudPuff: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.addEllipse(in: CGRect(x: 0, y: h * 0.35, width: w * 0.42, height: h * 0.55))
        p.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.2, width: w * 0.48, height: h * 0.62))
        p.addEllipse(in: CGRect(x: w * 0.42, y: h * 0.32, width: w * 0.48, height: h * 0.58))
        return p
    }
}
