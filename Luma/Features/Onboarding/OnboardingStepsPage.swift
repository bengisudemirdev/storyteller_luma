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
                            .padding(.top, 12)

                        Text("Üç kısa adımda kişisel masala ulaşırsın.")
                            .font(.system(size: OnboardingTypography.body, weight: .regular, design: .rounded))
                            .foregroundStyle(OnboardingPalette.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 12)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                            stepRow(number: item.0, title: item.1, caption: item.2)
                                .padding(.bottom, index == steps.count - 1 ? 0 : 8)
                        }
                    }
                    .padding(.top, 16)

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

    private func stepRow(number: Int, title: String, caption: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
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
                    .frame(width: 40, height: 40)

                Text("\(number)")
                    .font(.system(size: OnboardingTypography.body, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(stepLabel(for: number))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(OnboardingPalette.muted.opacity(0.72))

                Text(title)
                    .font(.system(size: OnboardingTypography.cardTitle, weight: .semibold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                Text(caption)
                    .font(.system(size: OnboardingTypography.bodySmall, weight: .regular, design: .rounded))
                    .foregroundStyle(OnboardingPalette.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
    }

    private func stepLabel(for number: Int) -> String {
        switch number {
        case 1:
            return "ADIM BİR"
        case 2:
            return "ADIM İKİ"
        case 3:
            return "ADIM ÜÇ"
        default:
            return "ADIM \(number)"
        }
    }
}

#Preview {
    ZStack {
        OnboardingWarmBackground()
        OnboardingStepsPage(onContinue: {})
    }
}
