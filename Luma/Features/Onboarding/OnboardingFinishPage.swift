import SwiftUI

struct OnboardingFinishPage: View {
    let onFinish: () -> Void

    @State private var ringPulse = false

    var body: some View {
        OnboardingPageLayout(
            scrollContent: {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .stroke(OnboardingPalette.goldSoft.opacity(0.35), lineWidth: 2)
                            .frame(width: ringPulse ? 118 : 100, height: ringPulse ? 118 : 100)
                            .opacity(ringPulse ? 0.4 : 0.75)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        OnboardingPalette.lavenderMist.opacity(0.9),
                                        OnboardingPalette.peachMist.opacity(0.5)
                                    ],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: 56
                                )
                            )
                            .frame(width: 88, height: 88)

                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [OnboardingPalette.accentPeach, OnboardingPalette.dustyBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: ringPulse)
                    .onAppear { ringPulse = true }

                    VStack(spacing: 14) {
                        Text("Masal zamanı başlasın")
                            .font(.system(size: OnboardingTypography.title, weight: .bold, design: .serif))
                            .foregroundStyle(OnboardingPalette.ink)
                            .multilineTextAlignment(.center)
                            .padding(.top, 32)

                        Text("Şimdi ilk adımı at ve Olia dünyasını keşfet.")
                            .font(.system(size: OnboardingTypography.body, weight: .regular, design: .rounded))
                            .foregroundStyle(OnboardingPalette.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 12)
                    }

                    Spacer(minLength: 0)
                }
            },
            footer: {
                OnboardingCTAButton(title: "Devam") {
                    onFinish()
                }
            }
        )
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        OnboardingFinishPage(onFinish: {})
    }
}
