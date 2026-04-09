import SwiftUI
import UIKit

/// İlk onboarding: sadece karşılama + CTA; özellikler sonraki sayfalarda.
struct OnboardingWelcomePage: View {
    let onFairyBurst: () -> Void

    @State private var contentVisible = false
    @State private var isTransitioning = false
    @State private var heroScale: CGFloat = 1
    @State private var glowOpacity: Double = 0
    @State private var heroFloat = false

    var body: some View {
        OnboardingPageLayout(
            scrollContent: {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    welcomeHeroMark
                        .scaleEffect(heroScale)
                        .padding(.bottom, 14)
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible ? 0 : 12)

                    VStack(spacing: 14) {
                        Text("Her gece, çocuğuna özel masallar")
                            .font(.system(size: OnboardingTypography.sectionTitle, weight: .bold, design: .serif))
                            .foregroundStyle(OnboardingPalette.titlePlum)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Kısa bir turda nasıl kullanacağını göstereceğiz.")
                            .font(.system(size: OnboardingTypography.body, weight: .regular, design: .rounded))
                            .foregroundStyle(OnboardingPalette.subtitleGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 8)
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 10)
                    .padding(.top, 4)

                    Spacer(minLength: 285)
                }
            },
            footer: {
                OnboardingCTAButton(title: "Başlayalım", isEnabled: !isTransitioning) {
                    playWelcomeTransition()
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 6)
            }
        )
        .animation(.easeOut(duration: 0.45), value: glowOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                contentVisible = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                heroFloat = true
            }
        }
    }

    private var welcomeHeroMark: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFF4E8"),
                            OnboardingPalette.peachMist.opacity(0.85),
                            OnboardingPalette.lavenderMist.opacity(0.55)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 72
                    )
                )
                .frame(width: 144, height: 144)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.75), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: OnboardingPalette.templateCTABrown.opacity(0.18), radius: 20, x: 0, y: 10)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            OnboardingPalette.goldSoft.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 16,
                        endRadius: 90
                    )
                )
                .opacity(glowOpacity)
                .frame(width: 144, height: 144)
                .allowsHitTesting(false)

            VStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "5C4B51"), OnboardingPalette.templateCTABrown],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(OnboardingPalette.titlePlum.opacity(0.88))
            }
            .offset(y: heroFloat ? -3 : 3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Olia, çocuğuna özel masallar")
    }

    private func playWelcomeTransition() {
        guard !isTransitioning else { return }
        isTransitioning = true

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            heroScale = 1.08
            glowOpacity = 0.65
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.easeOut(duration: 0.28)) {
                heroScale = 1
                glowOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onFairyBurst()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            isTransitioning = false
        }
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        OnboardingWelcomePage(onFairyBurst: {})
    }
}
