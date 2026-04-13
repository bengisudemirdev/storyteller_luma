import SwiftUI

/// Masal üretimi sırasında tam ekran; ana sayfa paleti ve yumuşak “peri tozu” animasyonu.
struct LoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let captionLines: [String] = [
        "Peri tozları sayfalara serpiliyor ✨",
        "Karakterler ve mekân canlanıyor…",
        "Uyku öncesine uygun sakin bir ton seçiliyor…",
        "Cümleler yumuşatılıyor, son dokunuşlar…"
    ]

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            RadialGradient(
                colors: [
                    LumaTheme.lavender.opacity(0.12),
                    HomeDashboardPalette.accentOrangeSoft.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            if !reduceMotion {
                StoryPrepAmbientSpecks()
            }

            VStack(spacing: 32) {
                Spacer(minLength: 24)

                StoryPrepHeroOrb(reduceMotion: reduceMotion)

                VStack(spacing: 14) {
                    Text("Masalın hazırlanıyor")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    HomeDashboardPalette.nightMid,
                                    HomeDashboardPalette.ink
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)

                    TimelineView(.periodic(from: .now, by: 2.35)) { context in
                        let step = Int(floor(context.date.timeIntervalSinceReferenceDate / 2.35))
                        let safeIdx = ((step % Self.captionLines.count) + Self.captionLines.count) % Self.captionLines.count
                        Text(Self.captionLines[safeIdx])
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 8)
                            .animation(.easeInOut(duration: 0.4), value: safeIdx)
                            .id(safeIdx)
                    }
                    .frame(minHeight: 52, alignment: .center)

                    StoryPrepProgressDots(reduceMotion: reduceMotion)
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 24)
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.cardSurface.opacity(0.92))
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 18, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    LumaTheme.lavender.opacity(0.25),
                                    HomeDashboardPalette.accentOrange.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                Spacer(minLength: 40)
            }
            .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
        }
    }
}

// MARK: - Hero

private struct StoryPrepHeroOrb: View {
    let reduceMotion: Bool
    @State private var pulse = false
    @State private var bob = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        LumaTheme.lavender.opacity(0.18 - Double(i) * 0.04),
                        lineWidth: 2
                    )
                    .frame(width: 108 + CGFloat(i) * 36, height: 108 + CGFloat(i) * 36)
                    .scaleEffect(reduceMotion ? 1 : (pulse ? 1.08 : 0.92))
                    .opacity(reduceMotion ? 0.35 : (pulse ? 0.5 : 0.85))
            }

            if !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 24, paused: false)) { context in
                    let angle = context.date.timeIntervalSinceReferenceDate * 32
                    ZStack {
                        ForEach(0..<6, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 11 + CGFloat(i % 3) * 2, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [HomeDashboardPalette.accentOrangeSoft, LumaTheme.lavender],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(y: -76)
                                .rotationEffect(.degrees(Double(i) * 60 + angle))
                                .opacity(0.75)
                        }
                    }
                }
            }

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HomeDashboardPalette.moonGlow.opacity(0.95),
                                LumaTheme.lavender.opacity(0.35),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 64
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 1)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                HomeDashboardPalette.cardSurface.opacity(0.95),
                                LumaTheme.lavender.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        LumaTheme.lavender.opacity(0.45),
                                        HomeDashboardPalette.accentOrange.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: LumaTheme.lavender.opacity(0.2), radius: 16, x: 0, y: 8)

                Image(systemName: "book.pages.fill")
                    .font(.system(size: 40, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [HomeDashboardPalette.nightMid, LumaTheme.lavender],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: reduceMotion ? 0 : (bob ? -5 : 5))
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bob = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Ambient specks

private struct StoryPrepAmbientSpecks: View {
    private static let specks: [Speck] = Speck.seeded(count: 42)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            TimelineView(.animation(minimumInterval: 1 / 20, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(Self.specks) { s in
                        speckView(s, t: t, in: CGSize(width: w, height: h))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func speckView(_ s: Speck, t: TimeInterval, in size: CGSize) -> some View {
        let wobble = sin(t * s.speed + s.phase) * 10
        let drift = cos(t * s.speed * 0.7 + s.phase * 1.3) * 8
        let x = size.width * s.u + wobble
        let y = size.height * s.v + drift
        let twinkle = 0.35 + 0.45 * (0.5 + 0.5 * sin(t * 2.2 + s.phase))

        return Group {
            if s.isStar {
                Image(systemName: "sparkle")
                    .font(.system(size: s.size, weight: .light))
                    .foregroundStyle(s.tint.opacity(twinkle))
            } else {
                Circle()
                    .fill(s.tint.opacity(twinkle * 0.85))
                    .frame(width: s.size, height: s.size)
                    .blur(radius: s.blur)
            }
        }
        .position(x: x, y: y)
    }

    private struct Speck: Identifiable {
        let id: Int
        let u: CGFloat
        let v: CGFloat
        let size: CGFloat
        let tint: Color
        let blur: CGFloat
        let speed: Double
        let phase: Double
        let isStar: Bool

        static func seeded(count: Int) -> [Speck] {
            (0..<count).map { i in
                let tints: [Color] = [
                    LumaTheme.lavender,
                    HomeDashboardPalette.accentOrangeSoft,
                    Color.white,
                    HomeDashboardPalette.nightMid.opacity(0.35)
                ]
                return Speck(
                    id: i,
                    u: pseudoUnit(i * 3 + 1),
                    v: pseudoUnit(i * 5 + 7),
                    size: 3 + pseudoUnit(i * 11) * 7,
                    tint: tints[i % tints.count],
                    blur: pseudoUnit(i * 13) < 0.4 ? 1.2 : 0,
                    speed: 0.35 + Double(pseudoUnit(i * 17)) * 0.55,
                    phase: Double(pseudoUnit(i * 19)) * .pi * 2,
                    isStar: pseudoUnit(i * 23) < 0.28
                )
            }
        }

        private static func pseudoUnit(_ seed: Int) -> CGFloat {
            let x = sin(Double(seed) * 12.9898) * 43758.5453
            let f = x.truncatingRemainder(dividingBy: 1)
            return CGFloat(abs(f))
        }
    }
}

// MARK: - Dots

private struct StoryPrepProgressDots: View {
    let reduceMotion: Bool
    @State private var step = 0
    @State private var advanceTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(
                        i == (reduceMotion ? 0 : step)
                            ? LumaTheme.lavender
                            : HomeDashboardPalette.creamDeep.opacity(0.9)
                    )
                    .frame(width: i == (reduceMotion ? 0 : step) ? 22 : 8, height: 8)
                    .overlay(
                        Capsule()
                            .stroke(LumaTheme.lavender.opacity(0.25), lineWidth: 1)
                    )
                    .animation(.spring(response: 0.45, dampingFraction: 0.72), value: step)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            advanceTask?.cancel()
            advanceTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    guard !Task.isCancelled else { break }
                    step = (step + 1) % 4
                }
            }
        }
        .onDisappear {
            advanceTask?.cancel()
            advanceTask = nil
        }
    }
}

#Preview("Masal hazırlanıyor") {
    LoadingView()
}
