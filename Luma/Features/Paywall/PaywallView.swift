import SwiftUI
import RevenueCat

enum PaywallSource {
    case storyLimitReached
    case childLimitReached
    case manual
}

#Preview("Story Limit") {
    PaywallView(source: .storyLimitReached)
        .environmentObject(SubscriptionManager())
}

#Preview("Child Limit") {
    PaywallView(source: .childLimitReached)
        .environmentObject(SubscriptionManager())
}

#Preview("Manual") {
    PaywallView(source: .manual)
        .environmentObject(SubscriptionManager())
}

struct PaywallView: View {
    let source: PaywallSource
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var animateGradient = false
    @State private var selectedPackage: PackageOption = .yearly
    @State private var showPolicies = false

    private enum PackageOption: String {
        case yearly
        case monthly
    }

    private let yearlyPrice: Double = 1100
    private let monthlyPrice: Double = 200

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()
            paywallSoulBackdrop

            ViewThatFits(in: .vertical) {
                paywallMainColumn(distributeVertically: true)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                ScrollView(showsIndicators: false) {
                    paywallMainColumn(distributeVertically: false)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            paywallTopBar
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
                .background(
                    Color(hex: "FAF6EF")
                        .opacity(0.94)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .sheet(isPresented: $showPolicies) {
            PoliciesDetailView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }

    /// Sığdığında bölümler arası boşlukları eşit büyüterek içeriği üst–alt arasındaki alana yayar; sığmazsa ScrollView’da sabit aralık kullanılır.
    @ViewBuilder
    private func paywallMainColumn(distributeVertically: Bool) -> some View {
        if distributeVertically {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    headlineBlock
                    brandSubtitleChip
                    paywallIntroText
                }

                Spacer(minLength: 12)
                billingPeriodSegment
                Spacer(minLength: 12)
                featuresBlockCompact
                Spacer(minLength: 12)
                pricingPanelCompact
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                headlineBlock
                brandSubtitleChip
                paywallIntroText
                billingPeriodSegment
                featuresBlockCompact
                pricingPanelCompact
            }
        }
    }

    private var paywallIntroText: some View {
        Text(introText)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundColor(HomeDashboardPalette.muted)
            .multilineTextAlignment(.leading)
            .lineSpacing(3)
            .lineLimit(3)
            .minimumScaleFactor(0.9)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Başlık (Olia sesi: gece, ritüel, birlikte)

    private var headlineBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                HomeDashboardPalette.moonGlow,
                                HomeDashboardPalette.nightMid.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: HomeDashboardPalette.accentOrangeSoft.opacity(0.35), radius: 8, x: 0, y: 2)

                Text(AppBrand.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(HomeDashboardPalette.muted)
                    .tracking(0.8)
            }

            (Text("Her gece birlikte, ") + Text("Premium").foregroundColor(LumaTheme.lavender) + Text(" masal zamanı"))
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(HomeDashboardPalette.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.82)
                .lineLimit(2)
        }
    }

    private var brandSubtitleChip: some View {
        Text(AppBrand.subtitle)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(HomeDashboardPalette.muted)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.75))
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 3)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.22), lineWidth: 1)
            )
    }

    // MARK: - Aylık / Yıllık segment

    private var billingPeriodSegment: some View {
        HStack(spacing: 0) {
            segmentChip(title: "Aylık", option: .monthly)
            segmentChip(title: "Yıllık", option: .yearly)
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.15), lineWidth: 1)
        )
    }

    private func segmentChip(title: String, option: PackageOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPackage = option
            }
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(selectedPackage == option ? .white : HomeDashboardPalette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background {
                    if selectedPackage == option {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [LumaTheme.lavender, HomeDashboardPalette.nightMid.opacity(0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Özellikler (kompakt: iki sütun)

    private var featuresBlockCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Masal dünyanda neler var?")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(HomeDashboardPalette.muted)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    PaywallFeatureLine(
                        icon: "book.pages.fill",
                        text: "Haftalık 7 masal oluşturma",
                        iconColor: HomeDashboardPalette.accentOrange,
                        compact: true
                    )
                    PaywallFeatureLine(
                        icon: "sparkles",
                        text: "Haftalık 5 masal seslendirme",
                        iconColor: LumaTheme.lavender,
                        compact: true
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    PaywallFeatureLine(
                        icon: "figure.2.and.child.holdinghands",
                        text: "Öncelikli premium erişim",
                        iconColor: HomeDashboardPalette.nightMid.opacity(0.75),
                        compact: true
                    )
                    PaywallFeatureLine(
                        icon: "heart.fill",
                        text: "Sakin ve reklamsız okuma",
                        iconColor: HomeDashboardPalette.accentOrangeSoft,
                        compact: true
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Fiyat paneli (kompakt)

    private var pricingPanelCompact: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ritüeline uygun plan")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(HomeDashboardPalette.muted)
                .textCase(.uppercase)
                .tracking(0.4)

            HStack(alignment: .top, spacing: 10) {
                PaywallBillingCard(
                    title: "Aylık",
                    priceLine: formattedPrice(monthlyPrice),
                    periodLine: "/ ay",
                    badge: nil,
                    isSelected: selectedPackage == .monthly,
                    compact: true
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPackage = .monthly
                    }
                }

                PaywallBillingCard(
                    title: "Yıllık",
                    priceLine: formattedPrice(yearlyPrice),
                    periodLine: "/ yıl",
                    badge: yearlySavingsBadge,
                    isSelected: selectedPackage == .yearly,
                    compact: true
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPackage = .yearly
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.12), lineWidth: 1)
        )
    }

    private var yearlySavingsBadge: String? {
        let fullYearMonthly = monthlyPrice * 12
        guard fullYearMonthly > yearlyPrice else { return nil }
        let pct = Int(round((1 - yearlyPrice / fullYearMonthly) * 100))
        guard pct > 0 else { return nil }
        return "−\(pct)%"
    }

    // MARK: - Alt bar

    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            Button(action: startPurchaseFlow) {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Masal dünyasını aç")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [LumaTheme.lavender, HomeDashboardPalette.nightMid.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: LumaTheme.lavender.opacity(0.38), radius: 18, x: 0, y: 8)
                )
            }

            Text("Ebeveyn destekli, güvenli içerik. İstediğin zaman iptal; Apple ID üzerinden yönetilir.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(HomeDashboardPalette.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            Button {
                Task { await restorePurchases() }
            } label: {
                Text("Satın alımları geri yükle")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(HomeDashboardPalette.accentOrange)
            }

            HStack(spacing: 6) {
                Button("Güvenlik ve gizlilik") {
                    showPolicies = true
                }
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(HomeDashboardPalette.muted)

                Text("·")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(HomeDashboardPalette.muted.opacity(0.5))

                Button("Şimdilik ücretsiz devam") {
                    dismiss()
                }
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(HomeDashboardPalette.muted)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .overlay(alignment: .top) {
            Divider().opacity(0.35)
        }
    }

    /// Kapatma tek satırda; içerik hemen altında başlar (üstte gereksiz boşluk bırakmaz).
    private var paywallTopBar: some View {
        HStack(alignment: .center) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HomeDashboardPalette.muted)
                    .padding(10)
                    .background(HomeDashboardPalette.cardSurface.opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Kapat"))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44, alignment: .center)
    }

    /// Ana sayfa gece kartıyla aynı his: yumuşak gece moru, ay parıltısı, minik yıldızlar.
    private var paywallSoulBackdrop: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            HomeDashboardPalette.moonGlow.opacity(animateGradient ? 0.45 : 0.32),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 102
                    )
                )
                .frame(width: 205, height: 205)
                .offset(x: animateGradient ? 130 : 150, y: animateGradient ? -120 : -100)
                .blur(radius: 2)

            Circle()
                .fill(HomeDashboardPalette.nightMid.opacity(animateGradient ? 0.11 : 0.07))
                .frame(width: 315, height: 315)
                .offset(x: animateGradient ? -110 : 100, y: animateGradient ? -210 : -150)
                .blur(radius: 50)

            Circle()
                .fill(HomeDashboardPalette.accentOrangeSoft.opacity(animateGradient ? 0.2 : 0.12))
                .frame(width: 252, height: 252)
                .offset(x: animateGradient ? 95 : -85, y: animateGradient ? 240 : 200)
                .blur(radius: 42)

            PaywallStarSpeckleField(phase: animateGradient)
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 22).repeatForever(autoreverses: true), value: animateGradient)
    }

    private func formattedPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "₺\(value)"
    }

    private var introText: String {
        switch source {
        case .storyLimitReached:
            return "Free planda haftalık 1 masal hakkı bulunur. Premium ile haftada 7 masal oluşturabilir, 5 masalı seslendirebilirsin."
        case .childLimitReached:
            return "Premium ile ailedeki herkes için daha zengin masal deneyimi açılır."
        case .manual:
            return "Premium plan: aylık ₺200 veya yıllık ₺1100. Haftalık 7 masal oluşturma ve 5 seslendirme hakkı."
        }
    }

    // MARK: - RevenueCat

    private func startPurchaseFlow() {
        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                guard let current = offerings.current else { return }
                let packages = current.availablePackages
                let chosen: Package? = {
                    switch selectedPackage {
                    case .monthly:
                        return packages.first { $0.packageType == .monthly }
                    case .yearly:
                        return packages.first { $0.packageType == .annual }
                    }
                }()
                guard let package = chosen ?? packages.first else { return }
                let result = try await Purchases.shared.purchase(package: package)
                if result.customerInfo.entitlements.active["oliapremium"] != nil
                    || result.customerInfo.entitlements.active["lumapremium"] != nil
                    || result.customerInfo.entitlements.active["premium"] != nil {
                    await subscriptionManager.refreshPlanFromServer()
                    dismiss()
                }
            } catch {}
        }
    }

    private func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            if info.entitlements.active["oliapremium"] != nil
                || info.entitlements.active["lumapremium"] != nil
                || info.entitlements.active["premium"] != nil {
                await subscriptionManager.refreshPlanFromServer()
                dismiss()
            }
        } catch {}
    }
}

// MARK: - Satır özellik

private struct PaywallFeatureLine: View {
    let icon: String
    let text: String
    var iconColor: Color = LumaTheme.lavender
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: compact ? 8 : 12) {
            Image(systemName: icon)
                .font(.system(size: compact ? 17 : 18, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: compact ? 24 : 26, alignment: .center)
                .padding(.top, compact ? 1 : 1)

            Text(text)
                .font(.system(size: compact ? 14 : 15, weight: .regular, design: .rounded))
                .foregroundColor(HomeDashboardPalette.ink)
                .multilineTextAlignment(.leading)
                .lineSpacing(compact ? 2 : 3)
                .lineLimit(compact ? 3 : nil)
                .minimumScaleFactor(compact ? 0.88 : 1)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

/// Gece gökyüzünde birkaç küçük yıldız (dashboard ile aynı ruh).
private struct PaywallStarSpeckleField: View {
    var phase: Bool

    private let specks: [(x: CGFloat, y: CGFloat, s: CGFloat)] = [
        (-140, -280, 2.6), (120, -240, 2.1), (-40, -200, 2.9),
        (160, 120, 2.4), (-130, 80, 1.9), (40, 200, 2.7)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(specks.enumerated()), id: \.offset) { i, s in
                Circle()
                    .fill(HomeDashboardPalette.starTint.opacity(phase ? 0.35 + Double(i % 3) * 0.08 : 0.22))
                    .frame(width: s.s, height: s.s)
                    .offset(x: s.x, y: s.y)
            }
        }
    }
}

// MARK: - Fiyat kartı (yan yana)

private struct PaywallBillingCard: View {
    let title: String
    let priceLine: String
    let periodLine: String
    let badge: String?
    let isSelected: Bool
    var compact: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: compact ? 7 : 8) {
                HStack {
                    Spacer(minLength: 0)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(
                            isSelected ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.muted.opacity(0.35)
                        )
                }

                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(LumaTheme.lavender)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LumaTheme.lavender.opacity(0.12))
                        .clipShape(Capsule(style: .continuous))
                } else {
                    Color.clear.frame(height: 24)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(HomeDashboardPalette.muted)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(priceLine)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(HomeDashboardPalette.ink)
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                    Text(periodLine)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(HomeDashboardPalette.muted)
                }
            }
            .padding(compact ? 11 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                            ? HomeDashboardPalette.accentOrangeSoft.opacity(0.22)
                            : HomeDashboardPalette.creamDeep.opacity(0.65)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? LumaTheme.lavender : HomeDashboardPalette.muted.opacity(0.12),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
