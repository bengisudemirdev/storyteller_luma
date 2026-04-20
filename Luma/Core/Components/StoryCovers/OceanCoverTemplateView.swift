import SwiftUI

/// Deniz: dalgalar, kabarcıklar, sakin sualtı hissi.
struct OceanCoverTemplateView: View {
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
                    Color(hex: "C8E8F0"),
                    Color(hex: "8FD0E0"),
                    Color(hex: "5AB0C0")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Işık huzmesi
            LinearGradient(
                colors: [
                    Color.white.opacity(0.35),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: width * 0.5)

            WaveShape(phase: 0)
                .fill(Color(hex: "7BC8D8").opacity(0.35))
                .frame(height: width * 0.35)
                .offset(y: width * 0.15)

            WaveShape(phase: .pi / 2)
                .fill(Color(hex: "5AB8C8").opacity(0.28))
                .frame(height: width * 0.32)
                .offset(y: width * 0.28)

            // Kabarcıklar
            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                    .frame(
                        width: CGFloat(6 + (i % 4) * 3),
                        height: CGFloat(6 + (i % 4) * 3)
                    )
                    .offset(
                        x: CGFloat([-60, 40, -30, 70, 20, -50, 55, -10, 35, 0][i]),
                        y: CGFloat([20, 40, 80, 55, 100, 65, 90, 110, 75, 130][i])
                    )
            }

            Image(systemName: "fish.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "E8F8FC").opacity(0.85), Color(hex: "B8E0EC")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(x: width * 0.22, y: -width * 0.15)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            Image(systemName: "leaf.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "6AB0A0").opacity(0.4))
                .rotationEffect(.degrees(-40))
                .offset(x: -width * 0.28, y: width * 0.02)

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

private struct WaveShape: Shape {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.55))
        for x in stride(from: 0, through: w, by: 4) {
            let relative = x / w
            let y = h * 0.45 + sin(relative * .pi * 2 + phase) * h * 0.12
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}
