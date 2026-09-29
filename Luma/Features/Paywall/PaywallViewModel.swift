import Foundation
import Combine
import RevenueCat

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published private(set) var isLoadingOfferings = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published var selectedPackageType: PaywallPlanType = .monthly
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published private(set) var monthlyPackage: Package?
    @Published private(set) var yearlyPackage: Package?
    @Published private(set) var activeSubscriptionProductID: String?
    @Published private(set) var offeringsDiagnostics: String = ""

    /// Offering çekildi; ikisi de nil ise tam yükleme başarısız veya boş offering kabul edilir.
    @Published private(set) var didAttemptOfferingsLoad = false

    var premiumPlanCardData: PaywallPlanViewData {
        PaywallPlanViewData.premiumPlan(priceText: priceDisplay(for: monthlyPackage, fallback: PaywallPlanViewData.monthlyFallbackPrice))
    }

    var yearlyPlanCardData: PaywallPlanViewData {
        PaywallPlanViewData.yearlyPlan(priceText: priceDisplay(for: yearlyPackage, fallback: PaywallPlanViewData.yearlyFallbackPrice))
    }

    var primaryCTATitle: String {
        if isCurrentSelectionOwned {
            return "Bu plan zaten aktif"
        }
        switch selectedPackageType {
        case .monthly:
            return "Aylık Premium’a Geç"
        case .yearly:
            return "Yıllık Premium’a Geç"
        }
    }

    /// Bu paket kullanıcının App Store / backend’deki mevcut aboneliği mi?
    func isPlanOwned(_ type: PaywallPlanType) -> Bool {
        guard let activeSubscriptionProductID else { return false }
        return package(for: type).map {
            RevenueCatCatalog.normalize($0.storeProduct.productIdentifier) == activeSubscriptionProductID
        } ?? false
    }

    var isCurrentSelectionOwned: Bool {
        isPlanOwned(selectedPackageType)
    }

    /// Seçili paket RevenueCat’ten satın alınabilir mi (sahip olunan veya alt seviye seçimde hayır).
    var canPurchaseSelectedPlan: Bool {
        if isCurrentSelectionOwned { return false }
        return package(for: selectedPackageType) != nil
    }

    var isSelectedPackageInStore: Bool {
        package(for: selectedPackageType) != nil
    }

    var unavailableSelectionMessage: String? {
        guard didAttemptOfferingsLoad && !isLoadingOfferings && !canPurchaseSelectedPlan else { return nil }
        if isCurrentSelectionOwned {
            return "Bu plan hesabında zaten aktif görünüyor."
        }
        return "Seçili plan App Store’dan yüklenemedi. Lütfen tekrar dene."
    }

    /// Paywall açılınca mevcut aboneliğe göre seçimi hizala (işaret görünsün).
    func syncSelectionWithEntitlements() {
        selectedPackageType = .monthly
    }

    var purchaseStatusFootnote: String {
        if isPurchasing {
            return hasBegunPurchaseTransaction ? "İşlem tamamlanıyor..." : "Satın alma başlatılıyor..."
        }
        return ""
    }

    private var hasBegunPurchaseTransaction = false

    func loadOfferings() async {
        guard !isLoadingOfferings else { return }
        isLoadingOfferings = true
        errorMessage = nil
        defer {
            isLoadingOfferings = false
            didAttemptOfferingsLoad = true
        }

        do {
            let resolved = try await RevenueCatSubscriptionPaywallService.fetchSubscriptionPackages()
            monthlyPackage = resolved.monthly
            yearlyPackage = resolved.yearly
            offeringsDiagnostics = resolved.diagnostics
            if resolved.monthly == nil && resolved.yearly == nil {
                errorMessage = "Premium paketleri şu an App Store’dan yüklenemedi. Lütfen tekrar dene."
            } else {
                await syncActiveSubscription()
            }
        } catch {
            monthlyPackage = nil
            yearlyPackage = nil
            offeringsDiagnostics = "offerings error=\(String(describing: error))"
            errorMessage = "Premium paketleri şu an App Store’dan yüklenemedi. Lütfen tekrar dene."
        }
    }

    func purchaseSelectedPackage() async -> Bool {
        guard canPurchaseSelectedPlan else { return false }
        guard let package = package(for: selectedPackageType) else {
            errorMessage = "Seçtiğin paket şu an kullanılamıyor. Biraz sonra tekrar dene."
            return false
        }

        isPurchasing = true
        hasBegunPurchaseTransaction = false
        errorMessage = nil
        successMessage = nil

        defer {
            isPurchasing = false
            hasBegunPurchaseTransaction = false
        }

        do {
            try await Task.sleep(nanoseconds: 120_000_000)
            hasBegunPurchaseTransaction = true
            let customerInfo = try await RevenueCatSubscriptionPaywallService.purchase(package: package)
            let freshInfo = try await RevenueCatSubscriptionPaywallService.refreshCustomerInfo()

            await refreshBackendEntitlements(customerInfo: customerInfo)

            let paidInStore = RevenueCatSubscriptionPaywallService.hasActiveSubscription(freshInfo)
                || RevenueCatSubscriptionPaywallService.hasActiveSubscription(customerInfo)

            // Ödeme App Store'da alındıysa backend senkronu gecikmiş olabilir: bir kez daha dene.
            if !EntitlementStore.shared.hasPremiumAccess, paidInStore {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await refreshBackendEntitlements(customerInfo: freshInfo)
            }

            guard EntitlementStore.shared.hasPremiumAccess else {
                if paidInStore {
                    // Kullanıcı ödeme yaptı: "hata" göstermek yanlış olur (tekrar satın almaya iter).
                    successMessage = "Ödemen alındı. Aboneliğin birkaç dakika içinde etkinleşecek; etkinleşmezse Satın alımları geri yükle'yi dene."
                    return true
                }
                errorMessage = "Satın alma sırasında bir hata oluştu. Lütfen tekrar deneyin."
                return false
            }

            successMessage = "Aboneliğin hazır. İyi dinlemeler!"
            return true
        } catch let error as Error where error.isPurchaseCancelledError || error.isCancellationError {
            successMessage = "Satın alma iptal edildi."
            return false
        } catch {
            errorMessage = "Satın alma sırasında bir hata oluştu. Lütfen tekrar deneyin."
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isRestoring = true
        errorMessage = nil
        successMessage = nil
        defer { isRestoring = false }

        do {
            try await RevenueCatSubscriptionPaywallService.restorePurchases()
            let merged = try await RevenueCatSubscriptionPaywallService.refreshCustomerInfo()
            await refreshBackendEntitlements(customerInfo: merged)

            if EntitlementStore.shared.hasPremiumAccess {
                successMessage = "Satın alımların geri yüklendi."
                return true
            }

            errorMessage = nil
            successMessage = "Aktif abonelik bulunamadı."
            return false
        } catch {
            errorMessage = "Geri yükleme tamamlanamadı. Bağlantını kontrol edip tekrar deneyin."
            return false
        }
    }

    func clearTransientMessages() {
        successMessage = nil
    }

    private func package(for type: PaywallPlanType) -> Package? {
        switch type {
        case .monthly:
            return monthlyPackage
        case .yearly:
            return yearlyPackage
        }
    }

    private func priceDisplay(for package: Package?, fallback: String) -> String {
        guard let package else { return fallback }
        let sp = package.storeProduct
        let raw = sp.localizedPriceString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return fallback }

        let lower = raw.lowercased()
        if lower.contains("/") || lower.contains("month") || lower.contains("ay") || lower.contains("mois") {
            return raw
        }

        if let period = sp.subscriptionPeriod, period.unit == .month, period.value == 1 {
            return "\(raw) / ay"
        }

        if let period = sp.subscriptionPeriod, period.unit == .year, period.value == 1 {
            return "\(raw) / yıl"
        }

        return raw
    }

    private func syncActiveSubscription() async {
        guard let info = try? await RevenueCatSubscriptionPaywallService.refreshCustomerInfo() else { return }
        let supportedProductIDs = [monthlyPackage, yearlyPackage]
            .compactMap { $0?.storeProduct.productIdentifier }
            .map(RevenueCatCatalog.normalize)
        let activeIDs = Set(info.activeSubscriptions.map(RevenueCatCatalog.normalize))
        activeSubscriptionProductID = supportedProductIDs.first(where: activeIDs.contains)
        if activeSubscriptionProductID == yearlyPackage.map({ RevenueCatCatalog.normalize($0.storeProduct.productIdentifier) }) {
            selectedPackageType = .yearly
        } else if activeSubscriptionProductID != nil {
            selectedPackageType = .monthly
        }
    }

    private func refreshBackendEntitlements(customerInfo: CustomerInfo) async {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        if !AppConfig.isRevenueCatTestStoreMode {
            try? await CreditAPIService.syncIAP(.init(appUserId: RevenueCatIdentityService.currentAppUserID))
        }
        await EntitlementStore.shared.refreshFromBackend()
        await SubscriptionManager.shared.refreshPlanFromServer()
        _ = customerInfo
    }
}

private extension Error {
    var isPurchaseCancelledError: Bool {
        let nsError = self as NSError
        return nsError.domain == ErrorCode.errorDomain
            && nsError.code == ErrorCode.purchaseCancelledError.rawValue
    }

    var isCancellationError: Bool {
        self is CancellationError
    }
}
