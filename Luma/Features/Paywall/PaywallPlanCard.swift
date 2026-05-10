import SwiftUI

struct PaywallPlanCard: View {
    let plan: PaywallPlanViewData
    let isSelected: Bool
    /// Premium kartı biraz daha sıcak / öne çıkan görünüm.
    let style: PaywallPlanCardStyle
    let onSelect: () -> Void

    enum PaywallPlanCardStyle {
        case premiumPopular
        case family
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(badgeForeground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(badgeBackground)
                            )
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.muted.opacity(0.55))
                }

                Text(plan.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)

                Text(plan.priceText)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(plan.features, id: \.self) { feature in
                        featureRow(feature)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardFill)
                    .shadow(color: shadowColor, radius: style == .premiumPopular ? 14 : 10, x: 0, y: style == .premiumPopular ? 8 : 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func featureRow(_ text: String) -> some View {
        let emphasize = text.localizedCaseInsensitiveContains("sesli masal hakkı")
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.92))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: emphasize ? 14 : 13, weight: emphasize ? .bold : .medium, design: .rounded))
                .foregroundStyle(emphasize ? HomeDashboardPalette.ink : HomeDashboardPalette.ink.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var cardFill: Color {
        switch style {
        case .premiumPopular:
            return Color(hex: "FFF5EE").opacity(0.98)
        case .family:
            return Color.white.opacity(0.92)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return HomeDashboardPalette.accentOrange.opacity(0.55)
        }
        switch style {
        case .premiumPopular:
            return HomeDashboardPalette.accentOrange.opacity(0.28)
        case .family:
            return Color.black.opacity(0.06)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .premiumPopular:
            return HomeDashboardPalette.accentOrange.opacity(0.22)
        case .family:
            return Color.black.opacity(0.08)
        }
    }

    private var badgeBackground: Color {
        switch style {
        case .premiumPopular:
            return HomeDashboardPalette.accentOrange.opacity(0.22)
        case .family:
            return HomeDashboardPalette.nightMid.opacity(0.12)
        }
    }

    private var badgeForeground: Color {
        switch style {
        case .premiumPopular:
            return HomeDashboardPalette.accentOrange
        case .family:
            return HomeDashboardPalette.nightMid.opacity(0.85)
        }
    }
}
