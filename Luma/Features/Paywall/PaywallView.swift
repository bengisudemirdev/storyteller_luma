import SwiftUI
import RevenueCat

enum PaywallSource {
    case storyLimitReached
    case childLimitReached
    case manual
}

struct PaywallView: View {
    let source: PaywallSource
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LumaTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Text("Olia Premium")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(LumaTheme.text)
                        .padding(.top, 32)

                    Text(introText)
                        .font(.subheadline)
                        .foregroundColor(LumaTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Free vs Premium net sayısal özet
                    VStack(spacing: 12) {
                        Text("Ücretsiz planı koruyarak, sadece ihtiyacınız olduğunda genişletiyoruz.")
                            .font(.caption)
                            .foregroundColor(LumaTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ücretsiz planda neler var?")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(LumaTheme.text)
                            benefitRow(icon: "checkmark.circle.fill",
                                       title: "1 çocuk profili",
                                       subtitle: "Ücretsiz planda tek bir çocuk için profil oluşturabilirsiniz.")
                            benefitRow(icon: "checkmark.circle.fill",
                                       title: "Günde 3 yeni masal",
                                       subtitle: "Her gün en fazla 3 yeni masal oluşturabilirsiniz.")
                            benefitRow(icon: "checkmark.circle.fill",
                                       title: "En fazla 10 kayıtlı masal",
                                       subtitle: "Çocuğunuzun sevdiği en önemli masalları kaydetmeniz için alan.")
                            benefitRow(icon: "checkmark.circle.fill",
                                       title: "Aynı güvenli hikâye motoru",
                                       subtitle: "Her planda aynı güvenlik kuralları ve yaşa uyarlanmış dil kullanılır.")
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Premium ile neler açılıyor?")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(LumaTheme.text)
                            benefitRow(icon: "sparkles",
                                       title: "Günlük masal sınırı yok",
                                       subtitle: "Gün içinde birden fazla kez hikâye üretmek istediğinizde, sınıra takılmadan devam edebilirsiniz.")
                            benefitRow(icon: "person.3.fill",
                                       title: "Sınırsıza yakın çocuk profili",
                                       subtitle: "Ailede birden fazla çocuk varsa, her biri için ayrı profil, ayrı ilgi alanı ve hassasiyet tanımlayabilirsiniz.")
                            benefitRow(icon: "book.fill",
                                       title: "Daha geniş masal kütüphanesi",
                                       subtitle: "10’dan fazla masalı güvenle saklayın; sevilen hikâyeleri ileride tekrar okumak için her zaman elinizin altında tutun.")
                            benefitRow(icon: "text.book.closed.fill",
                                       title: "Daha uzun ve zengin hikâyeler",
                                       subtitle: "Uygun yaş gruplarında, daha detaylı ve katmanlı masallar oluşturarak hikâye deneyimini derinleştirebilirsiniz.")
                        }
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(24)
                        .shadow(color: LumaTheme.softShadow, radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        Button(action: startPurchaseFlow) {
                            Text("Olia Premium'u Aç")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LumaTheme.lavender)
                                .cornerRadius(18)
                        }

                        Button("Satın Alımları Geri Yükle") {
                            Task { await restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundColor(LumaTheme.lavender)

                        Button("Şimdilik Ücretsiz Devam Et") {
                            dismiss()
                        }
                        .font(.caption)
                        .foregroundColor(LumaTheme.secondaryText)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

                    Text("Olia, her planda aynı temel ilkeyi korur: ebeveyn destekli, yaşa uyarlanmış ve güvenli hikâye deneyimi. Premium, yalnızca miktarı ve konforu artırır; çocuklar için güvenlik kuralları asla değişmez.")
                        .font(.footnote)
                        .foregroundColor(LumaTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private var introText: String {
        switch source {
        case .storyLimitReached:
            return "Bugün ücretsiz masal hakkınızı doldurdunuz. Çocuğunuz Olia'yı seviyorsa, Premium ile masal sınırını yumuşakça kaldırabilirsiniz."
        case .childLimitReached:
            return "Ücretsiz planda bir çocuk profiline kadar destekliyoruz. Ailenizde birden fazla çocuk varsa, Premium ile herkes için ayrı masal dünyaları açabilirsiniz."
        case .manual:
            return "Olia Premium, masal deneyiminizi sınırları hafifleterek daha esnek ve konforlu hale getirir."
        }
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(LumaTheme.lavender)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LumaTheme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(LumaTheme.secondaryText)
            }
            Spacer()
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

