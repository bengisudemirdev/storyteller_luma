import SwiftUI
import RevenueCat

enum PaywallSource {
    case manual
    case insufficientCredits(required: Int)
}

struct PaywallView: View {
    let source: PaywallSource
    var onPurchaseCompleted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeViewModel = CreditStoreViewModel()
    @StateObject private var purchaseViewModel = PurchaseViewModel()
    @ObservedObject private var balanceViewModel = CreditBalanceViewModel.shared
    @State private var selectedPackageId: String?
    @State private var hasAppeared = false
    @State private var showAllPackages = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LumaWarmScreenBackground()
                if showAllPackages {
                    ScrollView(showsIndicators: false) {
                        contentStack
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                    }
                } else {
                    VStack(spacing: 0) {
                        contentStack
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                        Spacer(minLength: max(0, geo.safeAreaInsets.bottom - 2))
                    }
                }
            }
        }
        .task {
            if hasAppeared { return }
            hasAppeared = true
            await loadInitialData()
        }
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 9) {
            topBar
            header
            balanceCard
            fixedCostInfo
            freePlanInfo
            purchaseStatusBanner
            packageList
            footerActions
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

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(showAllPackages ? L10n.selectPackageTitle : L10n.storeTitle)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text(headerDescription)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            Spacer()
            Text("🧸")
                .font(.system(size: 30))
                .padding(.top, 4)
        }
    }

    private var balanceCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.currentBalance)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                Text("\(balanceViewModel.balance) \(L10n.creditUnit)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
            }
            Spacer()
            Button {
                Task { await balanceViewModel.refreshBalance() }
            } label: {
                if balanceViewModel.isRefreshing || purchaseViewModel.isBusy {
                    ProgressView().tint(HomeDashboardPalette.accentOrange)
                } else {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                }
            }
            .buttonStyle(.plain)
            .disabled(balanceViewModel.isRefreshing || purchaseViewModel.isBusy)
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )
        )
    }

    private var fixedCostInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.usageTitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
            UsageRow(icon: "sparkles.rectangle.stack.fill", text: L10n.storyCost)
            UsageRow(icon: "mic.fill", text: L10n.narrationCost)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }

    @ViewBuilder
    private var purchaseStatusBanner: some View {
        switch purchaseViewModel.state {
        case .idle:
            EmptyView()
        case .purchasing:
            InlineBanner(
                text: L10n.purchaseInProgress,
                tint: HomeDashboardPalette.nightMid
            )
        case .syncing:
            InlineBanner(
                text: L10n.purchaseSyncing,
                tint: HomeDashboardPalette.accentOrange
            )
        case .success:
            InlineBanner(
                text: L10n.purchaseSuccess,
                tint: Color.green.opacity(0.82)
            )
        case .cancelled:
            InlineBanner(
                text: L10n.purchaseCancelled,
                tint: HomeDashboardPalette.muted
            )
        case .syncFailed(let message):
            InlineBanner(
                text: message,
                tint: Color.red.opacity(0.8)
            )
        case .failed(let message):
            InlineBanner(
                text: message,
                tint: Color.red.opacity(0.8)
            )
        }
    }

    private var packageList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if storeViewModel.isLoading && storeViewModel.packages.isEmpty {
                CreditStoreLoadingView()
            } else if !storeViewModel.isLoading && displayPackages.isEmpty {
                CreditStoreEmptyOrErrorView(
                    message: L10n.packagesUnavailable,
                    retryTitle: L10n.retry,
                    onRetry: { Task { await storeViewModel.loadPackages() } }
                )
            } else {
                if showAllPackages {
                    ForEach(displayPackages) { item in
                        PackageChoiceCard(
                            item: item,
                            isSelected: item.id == selectedPackageId,
                            isUnavailable: item.purchasable == nil
                        ) {
                            selectedPackageId = item.id
                        }
                    }
                } else if let selectedItem {
                    PackageSummaryCard(item: selectedItem)
                }

                if !showAllPackages {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAllPackages = true
                        }
                    } label: {
                        HStack {
                            Label(L10n.showAllPackages, systemImage: "square.grid.2x2")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.84))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    guard let purchasable = selectedItem?.purchasable else { return }
                    Task { await purchase(purchasable) }
                } label: {
                    HStack(spacing: 8) {
                        if purchaseViewModel.isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text(primaryCTA)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                selectedItem?.purchasable == nil
                                    ? HomeDashboardPalette.muted.opacity(0.45)
                                    : HomeDashboardPalette.accentOrange
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(purchaseViewModel.isBusy || selectedItem?.purchasable == nil)

                Button {
                    Task { await purchaseViewModel.syncPurchasedCredits() }
                } label: {
                    Text(L10n.syncPurchases)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .underline()
                }
                .buttonStyle(.plain)
                .disabled(purchaseViewModel.isBusy)
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: 8) {
            if storeIsUnavailable {
                InlineBanner(
                    text: L10n.storeUnavailableBanner,
                    tint: HomeDashboardPalette.muted
                )
            }
            if balanceViewModel.isBalanceStale {
                InlineBanner(
                    text: L10n.staleBalanceWarning,
                    tint: Color.red.opacity(0.8)
                )
            }
            Text(L10n.footerInfo)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
        .frame(maxWidth: .infinity)
    }

    private var headerDescription: String {
        switch source {
        case .manual:
            return showAllPackages ? L10n.selectPackageSubtitle : L10n.manualSubtitle
        case .insufficientCredits(let required):
            return String(
                localized: "paywall.subtitle.insufficient",
                defaultValue: "Kredin yetersiz. Bu işlem için \(required) kredi gerekiyor. Paketini seçip devam edebilirsin."
            )
        }
    }

    private func loadInitialData() async {
        await balanceViewModel.syncFromBackend()
        await storeViewModel.loadPackages()
        if selectedPackageId == nil {
            selectedPackageId = displayPackages.first(where: { $0.config.title == "Plus" })?.id
                ?? displayPackages.first?.id
        }
    }

    private func purchase(_ package: RevenueCatCreditPackage) async {
        selectedPackageId = package.id
        await purchaseViewModel.purchase(package)
        if case .success = purchaseViewModel.state {
            onPurchaseCompleted?()
            if case .insufficientCredits = source {
                dismiss()
            }
            return
        }
        if case .syncFailed = purchaseViewModel.state {
            await balanceViewModel.refreshBalance()
        }
    }

    private var displayPackages: [StorePackageItem] {
        let packageMap = Dictionary(uniqueKeysWithValues: storeViewModel.packages.map { ($0.id, $0) })
        return CreditPackageConfig.all.map { config in
            StorePackageItem(config: config, purchasable: packageMap[config.id])
        }
    }

    private var storeIsUnavailable: Bool {
        !storeViewModel.isLoading && displayPackages.allSatisfy { $0.purchasable == nil }
    }

    private var selectedItem: StorePackageItem? {
        if let selectedPackageId {
            return displayPackages.first(where: { $0.id == selectedPackageId })
        }
        return displayPackages.first
    }

    private var primaryCTA: String {
        guard let item = selectedItem else { return L10n.unavailableCta }
        if showAllPackages {
            return "\(item.config.title) \(L10n.continueWithPackage)"
        }
        return "\(item.config.title) \(L10n.buySuffix)"
    }

    @ViewBuilder
    private var freePlanInfo: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🎁")
                .font(.system(size: 23))
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.freePlanTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                Text(L10n.freePlanBody)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                Text(L10n.freePlanNarrationRestriction)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.sectionCaption)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "FFF7E7"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HomeDashboardPalette.accentOrange.opacity(0.22), lineWidth: 1)
                )
        )
    }
}

#Preview {
    PaywallView(source: .manual)
}

private struct UsageRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.65)))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.58))
        )
    }
}

private struct PackageSummaryCard: View {
    let item: StorePackageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: packageIcon(for: item.config.id))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.7)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.config.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                    Text(item.config.credits.formattedWithDot + " kredi")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                    Text("\(L10n.approxPrefix) \(item.config.valueHint)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if let badge = item.config.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(HomeDashboardPalette.accentOrange.opacity(0.12))
                            )
                    }
                    Text(item.purchasable?.package.storeProduct.localizedPriceString ?? item.config.displayPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                }
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "FFF5EE"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(HomeDashboardPalette.accentOrange.opacity(0.45), lineWidth: 1.4)
                )
        )
    }

    private func packageIcon(for id: String) -> String {
        switch id {
        case "olia_credits_starter": return "paperplane.fill"
        case "olia_credits_plus": return "crown.fill"
        case "olia_credits_family": return "person.2.fill"
        case "olia_credits_mega": return "shippingbox.fill"
        default: return "sparkles"
        }
    }
}

private struct PackageChoiceCard: View {
    let item: StorePackageItem
    let isSelected: Bool
    let isUnavailable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: packageIcon(for: item.config.id))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.68)))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(item.config.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink)
                        if let badge = item.config.badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.accentOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(HomeDashboardPalette.accentOrange.opacity(0.12)))
                        }
                }
                    Text(item.config.credits.formattedWithDot + " kredi")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                    Text("\(L10n.approxPrefix) \(item.config.valueHint)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                    if isUnavailable {
                        Text(L10n.unavailableHint)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)
                    }
                }

                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(item.purchasable?.package.storeProduct.localizedPriceString ?? item.config.displayPrice)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.muted.opacity(0.6))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color(hex: "FFF5EE") : Color.white.opacity(0.84))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? HomeDashboardPalette.accentOrange.opacity(0.5) : Color.black.opacity(0.05),
                                lineWidth: isSelected ? 1.4 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func packageIcon(for id: String) -> String {
        switch id {
        case "olia_credits_starter": return "paperplane.fill"
        case "olia_credits_plus": return "crown.fill"
        case "olia_credits_family": return "person.2.fill"
        case "olia_credits_mega": return "shippingbox.fill"
        default: return "sparkles"
        }
    }
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
                .fill(tint.opacity(0.2))
        )
    }
}

private extension Int {
    var formattedWithDot: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

private struct StorePackageItem: Identifiable {
    var id: String { config.id }
    let config: CreditPackageConfig
    let purchasable: RevenueCatCreditPackage?
}

private enum L10n {
    static let storeTitle = String(localized: "paywall.title", defaultValue: "Kredi Paketleri")
    static let selectPackageTitle = String(localized: "paywall.selectPackageTitle", defaultValue: "Paket Seç")
    static let manualSubtitle = String(localized: "paywall.subtitle.manual", defaultValue: "Abonelik yerine kredi al, dilediğin zaman kullan.")
    static let selectPackageSubtitle = String(localized: "paywall.selectPackageSubtitle", defaultValue: "İhtiyacına uygun kredi paketini seç.")
    static let purchaseInProgress = String(localized: "paywall.purchase.inProgress", defaultValue: "Satın alma işlemi devam ediyor...")
    static let purchaseSyncing = String(localized: "paywall.purchase.syncing", defaultValue: "Satın alma tamamlandı. Kredi bakiyesi senkronize ediliyor...")
    static var purchaseSuccess: String {
        if AppConfig.isRevenueCatTestStoreMode {
            return String(localized: "paywall.purchase.success.testStore", defaultValue: "Test satın alma başarılı. Gerçek kredi yansıması için App Store ortamında tekrar test edebilirsin.")
        }
        return String(localized: "paywall.purchase.success", defaultValue: "Kredin güncellendi. Keyifle devam edebilirsin.")
    }
    static let packagesUnavailable = String(localized: "paywall.packages.unavailable", defaultValue: "Kredi paketleri şu an yüklenemedi.")
    static let storeUnavailableBanner = String(localized: "paywall.packages.storeUnavailableBanner", defaultValue: "Canlı App Store fiyatları alınamıyor. Kısa süre sonra tekrar deneyebilirsin.")
    static let retry = String(localized: "common.retry", defaultValue: "Tekrar Dene")
    static let buySuffix = String(localized: "paywall.buySuffix", defaultValue: "Paketi Al")
    static let continueWithPackage = String(localized: "paywall.continueWithPackage", defaultValue: "Paketi ile Devam Et")
    static let unavailableCta = String(localized: "paywall.unavailableCta", defaultValue: "Geçici olarak kullanılamıyor")
    static let unavailableHint = String(localized: "paywall.unavailableHint", defaultValue: "Bu paket şu anda App Store bağlantısında görünmüyor.")
    static let syncPurchases = String(localized: "paywall.syncPurchases", defaultValue: "Satın alımları geri yükle")
    static let purchaseCancelled = String(localized: "paywall.purchase.cancelled", defaultValue: "Satın alma iptal edildi.")
    static let staleBalanceWarning = String(localized: "paywall.balance.stale", defaultValue: "Bakiye güncel olmayabilir. Lütfen biraz sonra tekrar yenile.")
    static var footerInfo: String {
        String(
            localized: "paywall.footer.info",
            defaultValue: "Ödemeler RevenueCat üzerinden App Store ile güvenle alınır. Gerçek kredi bakiyen sunucu tarafında yönetilir."
        )
    }
    static let currentBalance = String(localized: "paywall.balance.title", defaultValue: "Mevcut Kredin")
    static let creditUnit = String(localized: "paywall.balance.unit", defaultValue: "kredi")
    static let usageTitle = String(localized: "paywall.usage.title", defaultValue: "Kredini nasıl kullanırsın?")
    static let storyCost = String(localized: "paywall.usage.story", defaultValue: "1 masal = 500 kredi")
    static let narrationCost = String(localized: "paywall.usage.narration", defaultValue: "1 seslendirme = 3000 kredi")
    static let coverFree = String(localized: "paywall.usage.coverFree", defaultValue: "Kapak görseli ücretsiz")
    static let approxPrefix = String(localized: "paywall.package.approxPrefix", defaultValue: "Yaklaşık")
    static let showAllPackages = String(localized: "paywall.showAllPackages", defaultValue: "Tüm paketleri gör")
    static let freePlanTitle = String(localized: "paywall.free.title", defaultValue: "1000 başlangıç kredisi")
    static let freePlanBody = String(localized: "paywall.free.body", defaultValue: "Hemen yaklaşık 2 ücretsiz masal oluşturabilirsin.")
    static let freePlanNarrationRestriction = String(localized: "paywall.free.narrationRestriction", defaultValue: "Seslendirme ücretsiz planda dahil değildir.")
}

private struct CreditStoreLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .frame(height: 120)
                    .overlay {
                        ProgressView()
                            .tint(HomeDashboardPalette.accentOrange)
                    }
            }
        }
    }
}

private struct CreditStoreEmptyOrErrorView: View {
    let message: String
    let retryTitle: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .multilineTextAlignment(.center)
            Button(retryTitle, action: onRetry)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
        )
    }
}
