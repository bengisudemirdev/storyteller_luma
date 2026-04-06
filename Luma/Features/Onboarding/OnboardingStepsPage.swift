import SwiftUI

struct OnboardingStepsPage: View {
    let onContinue: () -> Void

    private let steps: [(Int, String, String)] = [
        (1, "Çocuk profili oluştur", "Yaş ve sevilen konular masalın kalbini oluşturur."),
        (2, "Tema veya masal türünü seç", "Uyku, macera, dostluk… Bu gece nasıl bir dünya istediğinizi seçin."),
        (3, "Hikâyeyi oluştur ve okumaya başla", "Metin hazır olunca sessizce okuyun veya seslendirin.")
    ]

    var body: some View {
        OnboardingPageLayout(
            scrollContent: {
                VStack(spacing: 0) {
                    VStack(spacing: 10) {
                        Text("Nasıl çalışır?")
                            .font(.system(size: OnboardingTypography.title, weight: .bold, design: .serif))
                            .foregroundStyle(OnboardingPalette.ink)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)

                        Text("Üç kısa adımda kişisel masala ulaşırsın.")
                            .font(.system(size: OnboardingTypography.body, weight: .regular, design: .rounded))
                            .foregroundStyle(OnboardingPalette.muted)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                            stepRow(number: item.0, title: item.1, caption: item.2, isLast: index == steps.count - 1)
                        }
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

    private func stepRow(number: Int, title: String, caption: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Text("\(number)")
                    .font(.system(size: OnboardingTypography.body, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        OnboardingPalette.goldSoft.opacity(0.55),
                                        OnboardingPalette.peachMist.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    )

                if !isLast {
                    Rectangle()
                        .fill(OnboardingPalette.muted.opacity(0.15))
                        .frame(width: 2, height: 36)
                        .padding(.top, 4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: OnboardingTypography.cardTitle, weight: .semibold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                Text(caption)
                    .font(.system(size: OnboardingTypography.bodySmall, weight: .regular, design: .rounded))
                    .foregroundStyle(OnboardingPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 8)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        OnboardingStepsPage(onContinue: {})
    }
}
