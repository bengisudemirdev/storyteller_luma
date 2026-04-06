import SwiftUI

struct OnboardingValuePage: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingPageLayout(
            scrollContent: {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("Her masal, çocuğa göre")
                            .font(.system(size: OnboardingTypography.title, weight: .bold, design: .serif))
                            .foregroundStyle(OnboardingPalette.ink)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)

                        Text("Olia, hikâyeleri yaş, ilgi alanları ve güvenlik ilkelerine göre yumuşatır; böylece uyku öncesi sakin bir ritim oluşur.")
                            .font(.system(size: OnboardingTypography.body, weight: .regular, design: .rounded))
                            .foregroundStyle(OnboardingPalette.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }

                    VStack(spacing: 14) {
                        valueRow(
                            icon: "figure.and.child.holdinghands",
                            title: "Yaşa uygun",
                            caption: "Anlatım ve uzunluk çocuğunun yaşına uyar."
                        )
                        valueRow(
                            icon: "shield.checkered",
                            title: "Güvenli içerik",
                            caption: "Korku ve sert temalar filtrelenir ya da nazikçe dönüştürülür."
                        )
                        valueRow(
                            icon: "heart.text.square.fill",
                            title: "Kişiselleştirilmiş hikâyeler",
                            caption: "İsim, sevilen konular ve ailenin sınırları masala işlenir."
                        )
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 0)
                }
            },
            footer: {
                OnboardingCTAButton(title: "Devam") {
                    onContinue()
                }
            }
        )
    }

    private func valueRow(icon: String, title: String, caption: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OnboardingPalette.lavenderMist.opacity(0.65),
                                OnboardingPalette.peachMist.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(OnboardingPalette.accentPeach.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: OnboardingTypography.cardTitle, weight: .semibold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                Text(caption)
                    .font(.system(size: OnboardingTypography.bodySmall, weight: .regular, design: .rounded))
                    .foregroundStyle(OnboardingPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        OnboardingValuePage(onContinue: {})
    }
}
