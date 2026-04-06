import SwiftUI

struct OnboardingStoryTypesPage: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingPageLayout(
            scrollContent: {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("İki güzel yol")
                            .font(.system(size: OnboardingTypography.title, weight: .bold, design: .serif))
                            .foregroundStyle(OnboardingPalette.ink)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)

                        Text("Ana ekranda hem klasik masalları keşfedebilir hem de tamamen size özel yeni hikâyeler üretebilirsiniz.")
                            .font(.system(size: OnboardingTypography.body, weight: .regular, design: .rounded))
                            .foregroundStyle(OnboardingPalette.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }

                    VStack(spacing: 14) {
                        storyTypeCard(
                            icon: "books.vertical.fill",
                            title: "Klasik masallar",
                            subtitle: "Sevilen peri masalları, yumuşatılmış ve uyku öncesine uygun anlatımla.",
                            gradient: [
                                HomeDashboardPalette.nightMid.opacity(0.55),
                                OnboardingPalette.dustyBlue.opacity(0.45)
                            ]
                        )
                        storyTypeCard(
                            icon: "wand.and.stars",
                            title: "Kişisel masallar",
                            subtitle: "Çocuğunuzun adıyla, temalarla ve hayal gücüyle anında yeni hikâyeler.",
                            gradient: [
                                OnboardingPalette.accentPeach.opacity(0.45),
                                OnboardingPalette.goldSoft.opacity(0.4)
                            ]
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

    private func storyTypeCard(icon: String, title: String, subtitle: String, gradient: [Color]) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: OnboardingTypography.cardTitle, weight: .semibold, design: .serif))
                    .foregroundStyle(OnboardingPalette.ink)
                Text(subtitle)
                    .font(.system(size: OnboardingTypography.bodySmall, weight: .regular, design: .rounded))
                    .foregroundStyle(OnboardingPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        OnboardingStoryTypesPage(onContinue: {})
    }
}
