import SwiftUI

// MARK: - Onboarding palette (beige, şeftali, lavanta, tozlu mavi)

enum OnboardingPalette {
    static let parchment = Color(hex: "FAF6EF")
    static let parchmentDeep = Color(hex: "F2E8DC")
    static let peachMist = Color(hex: "F4D4C8")
    static let lavenderMist = Color(hex: "DDD4E8")
    static let dustyBlue = Color(hex: "A8BED6")
    static let goldSoft = Color(hex: "E8C9A0")
    static let ink = Color(hex: "2C2A32")
    static let muted = Color(hex: "6B6560")
    static let accentPeach = Color(hex: "E8956A")
    /// Şablon onboarding: krem ekran, kahverengi CTA
    static let templateCream = Color(hex: "F5F0E6")
    static let templateCreamDeep = Color(hex: "F2EBE3")
    static let templateTaupeBottom = Color(hex: "D9CEC3")
    static let templateTitleBrown = Color(hex: "3A2F28")
    static let templateCTABrown = Color(hex: "8B6D58")
    /// Splash ve karşılama başlıkları (mürdüm-kahve)
    static let titlePlum = Color(hex: "5C4B51")
    /// İkincil metin (splash alt başlığı ile uyumlu)
    static let subtitleGray = Color(hex: "8E8E8E")
}

// MARK: - Arka plan

struct OnboardingWarmBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                OnboardingPalette.templateCream,
                OnboardingPalette.templateCreamDeep,
                OnboardingPalette.templateTaupeBottom.opacity(0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - CTA

struct OnboardingCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: OnboardingTypography.cardTitle, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule(style: .continuous)
                        .fill(OnboardingPalette.templateCTABrown)
                        .shadow(color: OnboardingPalette.templateCTABrown.opacity(0.28), radius: 12, x: 0, y: 5)
                )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}

/// Hafif basınç animasyonu (mikro etkileşim).
struct OnboardingScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Typography

enum OnboardingTypography {
    static let title: CGFloat = 30
    static let sectionTitle: CGFloat = 26
    static let body: CGFloat = 15
    static let bodySmall: CGFloat = 14
    static let cardTitle: CGFloat = 16
}

// MARK: - Sayfa göstergesi

struct OnboardingPageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(
                        index == current
                            ? OnboardingPalette.templateCTABrown
                            : OnboardingPalette.muted.opacity(0.28)
                    )
                    .frame(width: 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sayfa \(current + 1) / \(total)")
    }
}

// MARK: - Ortak sayfa iskeleti

/// Üstte kaydırılabilir içerik (butonların üstünde kalan alanı doldurur), altta sabit CTA.
struct OnboardingPageLayout<ScrollContent: View, Footer: View>: View {
    @ViewBuilder var scrollContent: () -> ScrollContent
    @ViewBuilder var footer: () -> Footer

    /// CTA + alt padding (yaklaşık; sabit hizalama için).
    private var bottomReservedHeight: CGFloat { 104 }

    var body: some View {
        GeometryReader { proxy in
            let scrollMin = max(0, proxy.size.height - bottomReservedHeight)

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        scrollContent()
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: scrollMin, alignment: .top)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer()
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
