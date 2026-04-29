import SwiftUI
import RevenueCat

enum PaywallSource {
    case manual
    case insufficientCredits(required: Int)
}

struct PaywallView: View {
    let source: PaywallSource

    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeViewModel = CreditStoreViewModel()
    @StateObject private var purchaseViewModel = PurchaseViewModel()
    @ObservedObject private var balanceViewModel = CreditBalanceViewModel.shared
    @State private var selectedPackageId: String?
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    topBar
                    header
                    balanceCard
                    fixedCostInfo
                    purchaseStatusBanner
                    packageList
                    footerActions
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .task {
            if hasAppeared { return }
            hasAppeared = true
            await loadInitialData()
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
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.storeTitle)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
            Text(headerDescription)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
        }
    }

    private var balanceCard: some View {
        CreditBalanceCard(
            balance: balanceViewModel.balance,
            isRefreshing: balanceViewModel.isRefreshing || purchaseViewModel.isBusy,
            onRefresh: {
                Task {
                    await balanceViewModel.refreshBalance()
                }
            }
        )
    }

    private var fixedCostInfo: some View {
        CreditUsageInfoCard()
    }

    @ViewBuilder
    private var purchaseStatusBanner: some View {
        switch purchaseViewModel.state {
        case .idle:
            EmptyView()
        case .purchasing:
            PurchaseStatusBanner(
                text: L10n.purchaseInProgress,
                tint: HomeDashboardPalette.nightMid
            )
        case .syncing:
            PurchaseStatusBanner(
                text: L10n.purchaseSyncing,
                tint: HomeDashboardPalette.accentOrange
            )
        case .success:
            PurchaseStatusBanner(
                text: L10n.purchaseSuccess,
                tint: Color.green.opacity(0.82)
            )
        case .failed(let message):
            PurchaseStatusBanner(
                text: message,
                tint: Color.red.opacity(0.8)
            )
        }
    }

    private var packageList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.packagesTitle)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)

            if storeIsUnavailable {
                PurchaseStatusBanner(
                    text: L10n.storeUnavailableBanner,
                    tint: HomeDashboardPalette.muted
                )
            }

            if storeViewModel.isLoading && storeViewModel.packages.isEmpty {
                CreditStoreLoadingView()
            }

            ForEach(displayPackages) { item in
                CreditPackageCard(
                    item: item,
                    isSelected: item.id == selectedPackageId,
                    isBusy: purchaseViewModel.isBusy,
                    isStoreUnavailable: storeIsUnavailable,
                    actionTitle: purchaseActionTitle(for: item),
                    onSelect: {
                        selectedPackageId = item.id
                    },
                    onPurchase: {
                        guard let purchasable = item.purchasable else { return }
                        Task { await purchase(purchasable) }
                    }
                )
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchaseViewModel.restore() }
            } label: {
                Text(L10n.restorePurchases)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
            }
            .buttonStyle(.plain)
            .disabled(purchaseViewModel.isBusy)

            Button {
                Task { await balanceViewModel.refreshBalance() }
            } label: {
                Text(L10n.refreshBalance)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            .buttonStyle(.plain)
            .disabled(purchaseViewModel.isBusy)

            Text(L10n.footerInfo)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerDescription: String {
        switch source {
        case .manual:
            return L10n.manualSubtitle
        case .insufficientCredits(let required):
            return String(
                localized: "paywall.subtitle.insufficient",
                defaultValue: "Kredin yetersiz. Bu işlem için \(required) kredi gerekiyor. Paketini seçip devam edebilirsin."
            )
        }
    }

    private func purchaseActionTitle(for item: StorePackageItem) -> String {
        guard item.purchasable != nil else {
            return L10n.unavailableCta
        }
        if item.id == selectedPackageId {
            return item.config.ctaTitle
        }
        return "\(item.config.title) \(L10n.buySuffix)"
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
            if case .insufficientCredits = source {
                dismiss()
            }
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
}

#Preview {
    PaywallView(source: .manual)
}

private struct CreditBalanceCard: View {
    let balance: Int
    let isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.currentBalance)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                Text("\(balance) \(L10n.creditUnit)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
            }
            Spacer()
            Button(action: onRefresh) {
                if isRefreshing {
                    ProgressView()
                        .tint(HomeDashboardPalette.accentOrange)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.24)))
                }
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
        )
    }
}

private struct CreditUsageInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.usageTitle)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
            Text(L10n.storyCost)
            Text(L10n.narrationCost)
            Text(L10n.coverFree)
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(HomeDashboardPalette.accentOrange)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
    }
}

private struct CreditPackageCard: View {
    let item: StorePackageItem
    let isSelected: Bool
    let isBusy: Bool
    let isStoreUnavailable: Bool
    let actionTitle: String
    let onSelect: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.config.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                    Text(item.config.subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                    Text("\(item.config.credits) kredi")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                    Text("\(L10n.approxPrefix) \(item.config.valueHint)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                }
                Spacer(minLength: 10)
                VStack(alignment: .trailing, spacing: 8) {
                    if let badge = item.config.badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(item.config.title == "Mega" ? HomeDashboardPalette.nightMid : HomeDashboardPalette.accentOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    item.config.title == "Mega"
                                        ? HomeDashboardPalette.nightMid.opacity(0.12)
                                        : HomeDashboardPalette.accentOrange.opacity(0.14)
                                )
                            )
                    }
                    Text(item.purchasable?.package.storeProduct.localizedPriceString ?? item.config.displayPrice)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                }
            }

            if item.purchasable == nil {
                Text(L10n.unavailableHint)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }

            Button(action: onPurchase) {
                HStack(spacing: 8) {
                    if isBusy && isSelected {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(actionTitle)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.purchasable == nil ? HomeDashboardPalette.muted.opacity(0.45) : HomeDashboardPalette.nightMid)
                )
            }
            .buttonStyle(.plain)
            .disabled(isBusy || item.purchasable == nil)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    isSelected
                        ? HomeDashboardPalette.accentOrangeSoft.opacity(0.28)
                        : HomeDashboardPalette.cardSurface
                )
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected
                        ? HomeDashboardPalette.accentOrange.opacity(0.55)
                        : (item.config.title == "Plus" ? HomeDashboardPalette.accentOrange.opacity(0.25) : Color.clear),
                    lineWidth: 1.8
                )
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .onTapGesture(perform: onSelect)
        .opacity((isStoreUnavailable && item.purchasable == nil) ? 0.95 : 1)
    }
}

private struct StorePackageItem: Identifiable {
    var id: String { config.id }
    let config: CreditPackageConfig
    let purchasable: RevenueCatCreditPackage?
}

private enum L10n {
    static let storeTitle = String(localized: "paywall.title", defaultValue: "Kredi Mağazası")
    static let manualSubtitle = String(localized: "paywall.subtitle.manual", defaultValue: "İhtiyacın kadar kredi al, dilediğin zaman kullan.")
    static let purchaseInProgress = String(localized: "paywall.purchase.inProgress", defaultValue: "Satın alma işlemi devam ediyor...")
    static let purchaseSyncing = String(localized: "paywall.purchase.syncing", defaultValue: "Satın alma tamamlandı. Kredi bakiyesi senkronize ediliyor...")
    static let purchaseSuccess = String(localized: "paywall.purchase.success", defaultValue: "Kredin güncellendi. Keyifle devam edebilirsin.")
    static let packagesUnavailable = String(localized: "paywall.packages.unavailable", defaultValue: "Kredi paketleri şu an yüklenemedi.")
    static let storeUnavailableBanner = String(localized: "paywall.packages.storeUnavailableBanner", defaultValue: "Canlı App Store fiyatları şu anda alınamıyor. Paketleri yine de görebilir ve kısa süre içinde tekrar deneyebilirsin.")
    static let packagesTitle = String(localized: "paywall.packages.title", defaultValue: "Kredi Paketleri")
    static let retry = String(localized: "common.retry", defaultValue: "Tekrar Dene")
    static let buySuffix = String(localized: "paywall.buySuffix", defaultValue: "Paketi Al")
    static let unavailableCta = String(localized: "paywall.unavailableCta", defaultValue: "Geçici olarak kullanılamıyor")
    static let unavailableHint = String(localized: "paywall.unavailableHint", defaultValue: "Bu paket şu anda App Store bağlantısında görünmüyor.")
    static let restorePurchases = String(localized: "paywall.restore", defaultValue: "Satın alımları geri yükle")
    static let refreshBalance = String(localized: "paywall.refreshBalance", defaultValue: "Bakiyeyi yenile")
    static let footerInfo = String(localized: "paywall.footer.info", defaultValue: "Ödemeler App Store üzerinden güvenle alınır. Gerçek kredi bakiyen sunucu tarafında yönetilir.")
    static let currentBalance = String(localized: "paywall.balance.title", defaultValue: "Mevcut Kredin")
    static let creditUnit = String(localized: "paywall.balance.unit", defaultValue: "kredi")
    static let usageTitle = String(localized: "paywall.usage.title", defaultValue: "Kredi kullanım bilgisi")
    static let storyCost = String(localized: "paywall.usage.story", defaultValue: "1 masal = 500 kredi")
    static let narrationCost = String(localized: "paywall.usage.narration", defaultValue: "1 seslendirme = 3000 kredi")
    static let coverFree = String(localized: "paywall.usage.coverFree", defaultValue: "Kapak görselleri ücretsizdir")
    static let approxPrefix = String(localized: "paywall.package.approxPrefix", defaultValue: "Yaklaşık")
}

private struct PurchaseStatusBanner: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }
}

private struct CreditStoreLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 132)
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
