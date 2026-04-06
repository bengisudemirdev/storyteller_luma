import SwiftUI

/// "Hadi Başlayalım" sonrası tüm ekranı yumuşak altın / krem peri tozu ile kaplar.
struct OnboardingFairyDustOverlay: View {
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0

    private let particles: [FairyDustParticle] = FairyDustParticle.seeded(count: 160)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Sıcak buğulu tabaka
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        OnboardingPalette.goldSoft.opacity(0.75),
                        OnboardingPalette.peachMist.opacity(0.55),
                        OnboardingPalette.lavenderMist.opacity(0.45)
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: max(w, h) * 0.95
                )
                .opacity(Double(min(1, progress * 1.15)))
                .scaleEffect(0.4 + progress * 0.85)
                .blur(radius: 1)

                LinearGradient(
                    colors: [
                        OnboardingPalette.parchment.opacity(0.15),
                        OnboardingPalette.goldSoft.opacity(0.35),
                        OnboardingPalette.parchment.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(Double(progress * 0.85))
                .ignoresSafeArea()

                ForEach(particles) { p in
                    particleView(p, in: CGSize(width: w, height: h))
                }
            }
            .frame(width: w, height: h)
            .contentShape(Rectangle())
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .onAppear {
            withAnimation(.timingCurve(0.2, 0.92, 0.12, 1.0, duration: 1.08)) {
                progress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.14) {
                onComplete()
            }
        }
    }

    private func particleView(_ p: FairyDustParticle, in size: CGSize) -> some View {
        let dx = p.u - 0.5
        let dy = p.v - 0.5
        let dist = sqrt(dx * dx + dy * dy)
        /// Merkezden dışa dalga: yakın parçacıklar önce belirir.
        let wave = max(0, min(1, (progress - dist * 0.42) / 0.58))
        let soft = wave * wave * (3 - 2 * wave)
        let drift: CGFloat = 28 * progress
        let x = size.width * p.u + dx * drift
        let y = size.height * p.v + dy * drift

        let opacity = soft * (1 - progress * 0.25) * Double(p.opacityMul)
        let scale = 0.2 + soft * 0.95

        return Group {
            if p.usesSparkle {
                Image(systemName: "sparkle")
                    .font(.system(size: p.baseSize, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                OnboardingPalette.goldSoft,
                                OnboardingPalette.accentPeach.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: OnboardingPalette.goldSoft.opacity(0.6), radius: 2, x: 0, y: 0)
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                p.tint.opacity(0.9),
                                p.tint.opacity(0.35)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: p.baseSize
                        )
                    )
                    .frame(width: p.baseSize * 1.2, height: p.baseSize * 1.2)
                    .blur(radius: p.blur)
            }
        }
        .position(x: x, y: y)
        .scaleEffect(scale)
        .opacity(opacity)
    }
}

private struct FairyDustParticle: Identifiable {
    let id: Int
    let u: CGFloat
    let v: CGFloat
    let baseSize: CGFloat
    let tint: Color
    let blur: CGFloat
    let usesSparkle: Bool
    let opacityMul: CGFloat

    static func seeded(count: Int) -> [FairyDustParticle] {
        (0..<count).map { i in
            let u = pseudoUnit(i * 3 + 1)
            let v = pseudoUnit(i * 7 + 2)
            let size: CGFloat = 3 + pseudoUnit(i * 11) * 9
            let tints: [Color] = [
                OnboardingPalette.goldSoft,
                Color.white,
                OnboardingPalette.accentPeach,
                OnboardingPalette.lavenderMist,
                OnboardingPalette.dustyBlue
            ]
            let tint = tints[i % tints.count]
            let blur: CGFloat = pseudoUnit(i * 13) < 0.35 ? 0.8 : 0
            let sparkle = pseudoUnit(i * 17) < 0.22
            let opMul: CGFloat = 0.55 + pseudoUnit(i * 19) * 0.55
            return FairyDustParticle(
                id: i,
                u: u,
                v: v,
                baseSize: size,
                tint: tint,
                blur: blur,
                usesSparkle: sparkle,
                opacityMul: opMul
            )
        }
    }

    /// Deterministik “rastgele” (0…1).
    private static func pseudoUnit(_ seed: Int) -> CGFloat {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        let f = x.truncatingRemainder(dividingBy: 1)
        return CGFloat(abs(f))
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        Text("Arka plan")
        OnboardingFairyDustOverlay(onComplete: {})
    }
}
