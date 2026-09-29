import SwiftUI

/// Masal üretimi sırasında tam ekran; ana sayfa paleti ve yumuşak “peri tozu” animasyonu.
struct LoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Verilirse, bir süre sonra "Beklemek istemiyorum" düğmesi çıkar (ekran dokunuşları bloklar; kaçış yolu olmalı).
    var onCancel: (() -> Void)? = nil
    @State private var showCancel = false

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

                    Text("Masal üretimi yaklaşık yarım dakika sürebilir. İstersen vazgeçebilirsin; tamamlanan masal kayıtlı masallarında görünür.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.top, 6)
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

                if showCancel, let onCancel {
                    Button(action: onCancel) {
                        Text("Beklemek istemiyorum")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(HomeDashboardPalette.accentOrange.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
        }
        .task {
            guard onCancel != nil else { return }
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { showCancel = true }
        }
    }
}

// MARK: - Hero

private struct StoryPrepHeroOrb: View {
    let reduceMotion: Bool
    @State private var pulse = false
    @State private var bob = false
    @State private var orbit = false

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
                            .rotationEffect(.degrees(Double(i) * 60))
                            .opacity(0.75)
                    }
                }
                // Tek sürekli dönüş (Core Animation): eskiden TimelineView ile saniyede 24 kez yeniden çiziliyordu.
                .rotationEffect(.degrees(orbit ? 360 : 0))
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
            withAnimation(.linear(duration: 11).repeatForever(autoreverses: false)) {
                orbit = true
            }
        }
    }
}

// MARK: - Ambient specks

private struct StoryPrepAmbientSpecks: View {
    private static let specks: [Speck] = Speck.seeded(count: 24)

    var body: some View {
        // Tek `Canvas` çizimi: eskiden 42 ayrı bulanık SwiftUI görünümü saniyede 20 kez yeniden hesaplanıyordu.
        TimelineView(.animation(minimumInterval: 1 / 12, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for s in Self.specks {
                    let wobble = sin(t * s.speed + s.phase) * 10
                    let drift = cos(t * s.speed * 0.7 + s.phase * 1.3) * 8
                    let x = size.width * s.u + wobble
                    let y = size.height * s.v + drift
                    let twinkle = 0.35 + 0.45 * (0.5 + 0.5 * sin(t * 2.2 + s.phase))
                    let rect = CGRect(x: x - s.size / 2, y: y - s.size / 2, width: s.size, height: s.size)
                    if s.isStar {
                        var star = Path()
                        star.move(to: CGPoint(x: x, y: y - s.size))
                        star.addLine(to: CGPoint(x: x + s.size * 0.3, y: y - s.size * 0.3))
                        star.addLine(to: CGPoint(x: x + s.size, y: y))
                        star.addLine(to: CGPoint(x: x + s.size * 0.3, y: y + s.size * 0.3))
                        star.addLine(to: CGPoint(x: x, y: y + s.size))
                        star.addLine(to: CGPoint(x: x - s.size * 0.3, y: y + s.size * 0.3))
                        star.addLine(to: CGPoint(x: x - s.size, y: y))
                        star.addLine(to: CGPoint(x: x - s.size * 0.3, y: y - s.size * 0.3))
                        star.closeSubpath()
                        context.fill(star, with: .color(s.tint.opacity(twinkle)))
                    } else {
                        context.fill(Path(ellipseIn: rect), with: .color(s.tint.opacity(twinkle * 0.85)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
