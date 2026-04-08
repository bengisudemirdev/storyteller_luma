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
    @State private var currentStep: PaywallStep = .intro

    private enum PackageOption: String {
        case yearly
        case monthly
    }

    private enum PaywallStep {
        case intro
        case checkout
    }

    private let yearlyPrice: Double = 499.99
    private let monthlyPrice: Double = 69.99

    var body: some View {
        ZStack {
            LumaTheme.bg.ignoresSafeArea()
            animatedBackground

            VStack(spacing: 0) {
                if currentStep == .intro {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            introProgressSection
                            introHeroSection
                            introOutcomeSection
                            marketingHighlightsSection
                            socialProofBadge
                            testimonialSection
                        }
                        .padding(.bottom, 20)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            heroSection
                            socialProofBadge
                            packageSelectionSection
                            featureListSection
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .safeAreaInset(edge: .bottom) {
            if currentStep == .intro {
                introCtaSection
                    .background(LumaTheme.bg.opacity(0.92))
            } else {
                ctaSection
                    .background(LumaTheme.bg.opacity(0.92))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }

    private var introHeroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Olia Premium", systemImage: "wand.and.stars")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.lavender)

            Text("Her geceyi beklenen bir masal ritüeline çevir")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(LumaTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)
                .lineSpacing(2)

            Text("Sadece bir hikaye değil; çocuğunuzla aranızdaki bağı güçlendiren, her gece tekrar etmek isteyeceğiniz bir rutin.")
                .font(.subheadline)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.97),
                            LumaTheme.lavender.opacity(0.16),
                            Color.white.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(LumaTheme.lavender.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: LumaTheme.softShadow, radius: 12, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var introProgressSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Adım 1/2")
                .font(.caption.weight(.semibold))
                .foregroundColor(LumaTheme.lavender)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(LumaTheme.lavender.opacity(0.12))
                .clipShape(Capsule())

            Text("Premium deneyimi keşfet")
                .font(.caption)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var introOutcomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Premium neyi değiştirir?")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                OutcomeChip(icon: "clock.fill", title: "Daha az bekleme", subtitle: "Anında yeni masal")
                OutcomeChip(icon: "heart.fill", title: "Daha güçlü bağ", subtitle: "Her gece devam eden ritüel")
            }

            HStack(spacing: 10) {
                OutcomeChip(icon: "person.3.fill", title: "Tüm çocuklar", subtitle: "Herkese özel profil")
                OutcomeChip(icon: "sparkles", title: "Daha zengin içerik", subtitle: "Yaşa uygun derin hikayeler")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }

    private var marketingHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Neden ebeveynler Premium'u seçiyor?")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            MarketingHighlightRow(
                title: "Sınırsız yeni hikaye",
                subtitle: "Günlük limit düşünmeden istediğin an yeni masal üret."
            )
            MarketingHighlightRow(
                title: "Tüm kardeşler için ayrı profil",
                subtitle: "Her çocuk için yaşa ve ilgiye uygun kişiselleştirme."
            )
            MarketingHighlightRow(
                title: "Daha akıcı ve reklamsız deneyim",
                subtitle: "Masal anını bölmeden, odaklı bir okuma deneyimi."
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(LumaTheme.lavender)
                Text("Olia Premium")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LumaTheme.lavender)
            }

            Text("Sınırsız Masal Dünyası")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(LumaTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)
                .lineSpacing(2)

            Text(introText)
                .font(.subheadline)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(2.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.97),
                                LumaTheme.lavender.opacity(0.14),
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .fill(LumaTheme.lavender.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .offset(x: 24, y: -40)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(LumaTheme.lavender.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: LumaTheme.softShadow.opacity(0.9), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var socialProofBadge: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.orange)
                .padding(.top, 2)
            Text("4.9/5  -  10.000+ ebeveynin tercihi")
                .font(.footnote.weight(.semibold))
                .foregroundColor(LumaTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LumaTheme.lavender.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var packageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planını seç")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            PackageCard(
                title: "Yıllık Plan",
                subtitle: "Ayda sadece \(formattedPrice(yearlyMonthlyEquivalent))",
                trailingPrice: formattedPrice(yearlyPrice) + "/yıl",
                isSelected: selectedPackage == .yearly,
                isHighlighted: true,
                badgeText: "En Popüler"
            ) {
                selectedPackage = .yearly
            }

            PackageCard(
                title: "Aylık Plan",
                subtitle: "Ayda \(formattedPrice(monthlyPrice))",
                trailingPrice: formattedPrice(monthlyPrice) + "/ay",
                isSelected: selectedPackage == .monthly,
                isHighlighted: false,
                badgeText: nil
            ) {
                selectedPackage = .monthly
            }
        }
        .padding(.horizontal, 20)
    }

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium ile gelenler")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            FeatureRow(text: "Sınırsız Masal Üretimi")
            FeatureRow(text: "Tüm Çocuklarınız İçin Profiller")
            FeatureRow(text: "Reklamsız Deneyim")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }

    private var ctaSection: some View {
        VStack(spacing: 8) {
            Button(action: startPurchaseFlow) {
                Text("Sihirli Dünyayı Aç")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(LumaTheme.lavender)
                    .cornerRadius(18)
                    .shadow(color: LumaTheme.lavender.opacity(0.25), radius: 10, x: 0, y: 6)
            }

            Text("İstediğin zaman iptal et. Apple ID üzerinden yönetilir.")
                .font(.caption2)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                Button {
                    Task { await restorePurchases() }
                } label: {
                    Text("Satın Alımları Geri Yükle")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LumaTheme.lavender)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Şimdilik Ücretsiz Devam Et")
                        .font(.caption)
                        .foregroundColor(LumaTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .overlay(alignment: .top) {
            Divider().opacity(0.4)
        }
    }

    private var introCtaSection: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = .checkout
                }
            } label: {
                Text("Devam Et: Planları ve Fiyatları Gör")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(LumaTheme.lavender)
                    .cornerRadius(18)
                    .shadow(color: LumaTheme.lavender.opacity(0.2), radius: 10, x: 0, y: 6)
            }

            Text("2. adımda sadece sana uygun paketi seçersin.")
                .font(.caption2)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            Button {
                dismiss()
            } label: {
                Text("Şimdilik Ücretsiz Devam Et")
                    .font(.caption)
                    .foregroundColor(LumaTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .overlay(alignment: .top) {
            Divider().opacity(0.4)
        }
    }

    private var testimonialSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(LumaTheme.lavender)
                Text("Ebeveyn yorumu")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(LumaTheme.secondaryText)
            }

            Text("\"Olia Premium sayesinde hikaye saati artık bir görev değil, günün en sevdiğimiz anı oldu.\"")
                .font(.footnote)
                .foregroundColor(LumaTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("- Elif, 2 çocuk annesi")
                .font(.caption)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.88))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(LumaTheme.secondaryText)
                .padding(10)
                .background(Color.white.opacity(0.92))
                .clipShape(Circle())
        }
        .padding(.top, 10)
        .padding(.trailing, 16)
    }

    private var animatedBackground: some View {
        ZStack {
            Circle()
                .fill(LumaTheme.lavender.opacity(animateGradient ? 0.18 : 0.1))
                .frame(width: 280, height: 280)
                .offset(x: animateGradient ? -120 : 110, y: animateGradient ? -220 : -160)
                .blur(radius: animateGradient ? 65 : 48)

            Circle()
                .fill(Color.white.opacity(animateGradient ? 0.5 : 0.35))
                .frame(width: 240, height: 240)
                .offset(x: animateGradient ? 120 : -110, y: animateGradient ? 250 : 170)
                .blur(radius: animateGradient ? 80 : 56)
        }
        .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animateGradient)
    }

    private var yearlyMonthlyEquivalent: Double {
        yearlyPrice / 12
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
            return "Bugünlük masal oluşturma limitine ulaştınız. Premium ile sınırsızca devam edebilirsiniz."
        case .childLimitReached:
            return "Ücretsiz planda tek profil desteklenir. Diğer çocuklarınız için de profil açmak ister misiniz?"
        case .manual:
            return "Olia Premium, masal deneyiminizi daha esnek ve konforlu hale getirir."
        }
    }

    // MARK: - RevenueCat

    private func startPurchaseFlow() {
        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                guard let package = offerings.current?.availablePackages.first else {
                    return
                }
                let result = try await Purchases.shared.purchase(package: package)
                if result.customerInfo.entitlements.active["premium"] != nil {
                    await subscriptionManager.refreshPlanFromServer()
                    dismiss()
                }
            } catch {
                // İptal veya hata durumunda sessiz kalıyoruz; istersen burada alert gösterebilirsin.
            }
        }
    }

    private func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            if info.entitlements.active["premium"] != nil {
                await subscriptionManager.refreshPlanFromServer()
                dismiss()
            }
        } catch {
            // Sessizce başarısız; istersen burada alert gösterebilirsin.
        }
    }
}

private struct PackageCard: View {
    let title: String
    let subtitle: String
    let trailingPrice: String
    let isSelected: Bool
    let isHighlighted: Bool
    let badgeText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(LumaTheme.text)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(LumaTheme.secondaryText)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(trailingPrice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LumaTheme.text)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: true, vertical: true)
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? LumaTheme.lavender : LumaTheme.secondaryText.opacity(0.5))
                    Text(isSelected ? "Seçili plan" : "Bu planı seç")
                        .font(.caption)
                        .foregroundColor(LumaTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let badgeText {
                    Text(badgeText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(LumaTheme.lavender)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.white : Color.white.opacity(0.93))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected || isHighlighted ? 2 : 1)
            )
            .shadow(color: isSelected ? LumaTheme.lavender.opacity(0.12) : LumaTheme.softShadow, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        if isSelected || isHighlighted { return LumaTheme.lavender }
        return LumaTheme.secondaryText.opacity(0.2)
    }
}

private struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("✅")
            Text(text)
                .font(.subheadline)
                .foregroundColor(LumaTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct MarketingHighlightRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(LumaTheme.lavender)
                    .font(.caption.weight(.bold))
                    .padding(.top, 2)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LumaTheme.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(subtitle)
                .font(.caption)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 22)
        }
    }
}

private struct OutcomeChip: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(LumaTheme.lavender)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(LumaTheme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(LumaTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(10)
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
    }
}

