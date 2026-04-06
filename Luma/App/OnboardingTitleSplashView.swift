import SwiftUI

/// Oturum açılmış, onboarding tamamlanmamışken: marka başlığı + alt başlık, ardından otomatik geçiş.
struct OnboardingTitleSplashView: View {
    let onFinished: () -> Void
    var duration: TimeInterval = 1.1

    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            splashBackground

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    moonMark

                    Text(AppBrand.displayName)
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(OnboardingTitleSplashPalette.titlePlum)

                    Text("Çocuğunuza Özel Uyku Masalları")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(OnboardingTitleSplashPalette.subtitleGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    bookDivider
                        .padding(.top, 8)
                }
                .opacity(contentOpacity)

                Spacer()
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.55)) {
                contentOpacity = 1
            }
            let waitNanoseconds = UInt64(max(duration, 0.2) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: waitNanoseconds)
            await MainActor.run {
                onFinished()
            }
        }
    }

    private var splashBackground: some View {
        ZStack {
            OnboardingTitleSplashPalette.screenCream
                .ignoresSafeArea()

            ScatteredStarsSplashLayer()
                .allowsHitTesting(false)
        }
    }

    private var moonMark: some View {
        Image(systemName: "moonphase.waning.crescent")
            .font(.system(size: 58, weight: .ultraLight))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "FFF2D6"),
                        Color(hex: "FFD9A0"),
                        Color(hex: "F0B87A")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color(hex: "FFC978").opacity(0.45), radius: 18, x: 0, y: 6)
    }

    private var bookDivider: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(OnboardingTitleSplashPalette.subtitleGray.opacity(0.22))
                .frame(height: 1)

            Image(systemName: "book.closed.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OnboardingTitleSplashPalette.subtitleGray.opacity(0.45))

            Rectangle()
                .fill(OnboardingTitleSplashPalette.subtitleGray.opacity(0.22))
                .frame(height: 1)
        }
        .padding(.horizontal, 48)
    }

}

// MARK: - Palette

private enum OnboardingTitleSplashPalette {
    static let screenCream = Color(hex: "FFF9F0")
    static let titlePlum = Color(hex: "5C4B51")
    static let subtitleGray = Color(hex: "8E8E8E")
}

// MARK: - Yıldızlar

private struct ScatteredStarsSplashLayer: View {
    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    private let stars: [Star] = [
        Star(id: 0, x: 0.12, y: 0.08, size: 5, opacity: 0.35),
        Star(id: 1, x: 0.22, y: 0.14, size: 4, opacity: 0.28),
        Star(id: 2, x: 0.78, y: 0.1, size: 5, opacity: 0.32),
        Star(id: 3, x: 0.88, y: 0.18, size: 4, opacity: 0.25),
        Star(id: 4, x: 0.15, y: 0.28, size: 3, opacity: 0.22),
        Star(id: 5, x: 0.92, y: 0.32, size: 4, opacity: 0.3),
        Star(id: 6, x: 0.08, y: 0.42, size: 4, opacity: 0.2),
        Star(id: 7, x: 0.55, y: 0.06, size: 3, opacity: 0.26),
        Star(id: 8, x: 0.38, y: 0.12, size: 4, opacity: 0.24),
        Star(id: 9, x: 0.72, y: 0.24, size: 3, opacity: 0.22),
        Star(id: 10, x: 0.18, y: 0.72, size: 4, opacity: 0.22),
        Star(id: 11, x: 0.85, y: 0.78, size: 5, opacity: 0.28),
        Star(id: 12, x: 0.42, y: 0.88, size: 4, opacity: 0.2),
        Star(id: 13, x: 0.62, y: 0.92, size: 3, opacity: 0.22),
        Star(id: 14, x: 0.28, y: 0.82, size: 4, opacity: 0.18)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: star.size))
                    .foregroundStyle(Color(hex: "FFE4B0").opacity(star.opacity))
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height
                    )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Title splash") {
    OnboardingTitleSplashView(onFinished: {})
}

#Preview("Splash -> Onboarding") {
    SplashToOnboardingPreviewHost()
}

private struct SplashToOnboardingPreviewHost: View {
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                OnboardingTitleSplashView(onFinished: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showSplash = false
                    }
                }, duration: 0.9)
            } else {
                OnboardingContainerView(onFinished: {})
            }
        }
    }
}
