import SwiftUI

enum PaywallSource {
    case manual
    case insufficientCredits(required: Int)
}

struct PaywallView: View {
    let source: PaywallSource
    var onPurchaseCompleted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var entitlements = EntitlementStore.shared
    @StateObject private var viewModel = PaywallViewModel()
    @State private var hasAppeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LumaWarmScreenBackground()
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            topBar
                            heroSection
                            planCardsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }

                    bottomBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, max(10, geo.safeAreaInsets.bottom + 6))
                        .background(
                            Rectangle()
                                .fill(Color.white.opacity(0.94))
                                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -4)
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
            }
        }
        .task {
            if hasAppeared { return }
            hasAppeared = true
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
            viewModel.syncSelectionWithEntitlements()
            await viewModel.loadOfferings()
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.9)))
            }
            .buttonStyle(.plain)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Masalları sadece okumayın, dinleyin")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("paywall.heroTitle")

            Text(heroDescription)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.9))
                    .padding(.top, 1)
                Text("Aynı masalı tekrar dinlemek hakkından düşmez.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.14), lineWidth: 1)
                    )
            )
        }
    }

    private var heroDescription: String {
        switch source {
        case .manual:
            return "Çocuğunuz için kişiselleştirilmiş masallar oluşturun ve doğal anlatıcı sesiyle sesli hale getirin."
        case .insufficientCredits:
            return "Bu özelliğe devam etmek için uygun bir plan seçebilirsiniz. Çocuğunuz için kişiselleştirilmiş masallar ve doğal anlatıcı sesi bir arada."
        }
    }

    private var planCardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.isLoadingOfferings {
                offeringsLoadingPlaceholder
            }

            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                InlineBanner(text: errorMessage, tint: Color.red.opacity(0.85))
            }

            if let successMessage = viewModel.successMessage, !successMessage.isEmpty {
                let tint = successMessage.contains("iptal") ? HomeDashboardPalette.muted : Color.green.opacity(0.82)
                InlineBanner(text: successMessage, tint: tint)
            }

            PaywallPlanCard(
                plan: viewModel.premiumPlanCardData,
                isSelected: viewModel.selectedPackageType == .monthly,
                isOwned: viewModel.isPlanOwned(.monthly),
                style: .premiumPopular
            ) {
                viewModel.selectedPackageType = .monthly
                viewModel.clearTransientMessages()
            }

            PaywallPlanCard(
                plan: viewModel.yearlyPlanCardData,
                isSelected: viewModel.selectedPackageType == .yearly,
                isOwned: viewModel.isPlanOwned(.yearly),
                style: .yearly
            ) {
                viewModel.selectedPackageType = .yearly
                viewModel.clearTransientMessages()
            }

            if viewModel.didAttemptOfferingsLoad,
               viewModel.monthlyPackage == nil && viewModel.yearlyPackage == nil,
               !viewModel.isLoadingOfferings {
                Button {
                    Task { await viewModel.loadOfferings() }
                } label: {
                    Text("Tekrar dene")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }

            if !viewModel.isSelectedPackageInStore && viewModel.didAttemptOfferingsLoad && !viewModel.isLoadingOfferings {
                InlineBanner(
                    text: "Seçtiğin plan şu an App Store’dan yüklenemedi. Tekrar dene veya daha sonra kontrol et.",
                    tint: HomeDashboardPalette.muted
                )
            }

        }
    }

    private var offeringsLoadingPlaceholder: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(HomeDashboardPalette.accentOrange)
            Text("Paketler yükleniyor...")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if viewModel.isPurchasing {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(HomeDashboardPalette.accentOrange)
                    Text(viewModel.purchaseStatusFootnote)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let unavailableSelectionMessage = viewModel.unavailableSelectionMessage {
                Text(unavailableSelectionMessage)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("paywall.purchase.unavailableReason")
            }

            Button {
                Task {
                    let ok = await viewModel.purchaseSelectedPackage()
                    if ok {
                        onPurchaseCompleted?()
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.primaryCTATitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            purchaseEnabled ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.muted.opacity(0.45)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!purchaseEnabled)
            .accessibilityIdentifier("paywall.purchase.primary")

            Text("Aboneliğin App Store hesabın üzerinden yönetilir.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            footerLinksRow
        }
    }

    private var purchaseEnabled: Bool {
        !viewModel.isPurchasing && !viewModel.isRestoring && viewModel.canPurchaseSelectedPlan
    }

    private var footerLinksRow: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    let restored = await viewModel.restorePurchases()
                    if restored {
                        onPurchaseCompleted?()
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isRestoring {
                        ProgressView()
                            .scaleEffect(0.85)
                            .tint(HomeDashboardPalette.accentOrange)
                    }
                    Text("Satın almayı geri yükle")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .underline()
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPurchasing || viewModel.isRestoring)
            .accessibilityIdentifier("paywall.restore")

            HStack(spacing: 16) {
                termsLink
                Text("·")
                    .foregroundStyle(HomeDashboardPalette.muted)
                privacyLink
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var termsLink: some View {
        if let url = AppConfig.termsOfServiceURL {
            Button("Kullanım Şartları") {
                openURL(url)
            }
            .foregroundStyle(HomeDashboardPalette.accentOrange)
        } else {
            Text("Kullanım Şartları")
                .foregroundStyle(HomeDashboardPalette.muted.opacity(0.55))
        }
    }

    @ViewBuilder
    private var privacyLink: some View {
        if let url = AppConfig.privacyPolicyURL {
            Button("Gizlilik Politikası") {
                openURL(url)
            }
            .foregroundStyle(HomeDashboardPalette.accentOrange)
        } else {
            Text("Gizlilik Politikası")
                .foregroundStyle(HomeDashboardPalette.muted.opacity(0.55))
        }
    }
}

#Preview {
    PaywallView(source: .manual)
}

private struct InlineBanner: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.14))
        )
    }
}
