import Foundation
import Combine
import RevenueCat

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published private(set) var isLoadingOfferings = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published var selectedPackageType: PaywallPlanType = .premium
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published private(set) var premiumPackage: Package?
    @Published private(set) var familyPackage: Package?

    /// Offering çekildi; ikisi de nil ise tam yükleme başarısız veya boş offering kabul edilir.
    @Published private(set) var didAttemptOfferingsLoad = false

    var premiumPlanCardData: PaywallPlanViewData {
        PaywallPlanViewData.premiumPlan(priceText: priceDisplay(for: premiumPackage, fallback: PaywallPlanViewData.premiumFallbackPrice))
    }

    var familyPlanCardData: PaywallPlanViewData {
        PaywallPlanViewData.familyPlan(priceText: priceDisplay(for: familyPackage, fallback: PaywallPlanViewData.familyFallbackPrice))
    }

    var primaryCTATitle: String {
        if isCurrentSelectionOwned {
            return "Bu plan zaten aktif"
        }
        if EntitlementStore.shared.hasFamilyAccess, selectedPackageType == .premium {
            return "Family planın aktif"
        }
        switch selectedPackageType {
        case .premium:
            return "Premium’a Geç"
        case .family:
            return "Family’ye Geç"
        }
    }

    /// Bu paket kullanıcının App Store / backend’deki mevcut aboneliği mi?
    func isPlanOwned(_ type: PaywallPlanType) -> Bool {
        let es = EntitlementStore.shared
        if es.hasFamilyAccess { return type == .family }
        if es.hasPremiumAccess { return type == .premium }
        return false
    }

    var isCurrentSelectionOwned: Bool {
        isPlanOwned(selectedPackageType)
    }

    /// Seçili paket RevenueCat’ten satın alınabilir mi (sahip olunan veya alt seviye seçimde hayır).
    var canPurchaseSelectedPlan: Bool {
        if isCurrentSelectionOwned { return false }
        if EntitlementStore.shared.hasFamilyAccess, selectedPackageType == .premium { return false }
        return package(for: selectedPackageType) != nil
    }

    var isSelectedPackageInStore: Bool {
        package(for: selectedPackageType) != nil
    }

    /// Paywall açılınca mevcut aboneliğe göre seçimi hizala (işaret görünsün).
    func syncSelectionWithEntitlements() {
        let es = EntitlementStore.shared
        if es.hasFamilyAccess {
            selectedPackageType = .family
        } else if es.hasPremiumAccess {
            selectedPackageType = .premium
        }
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
            premiumPackage = resolved.premium
            familyPackage = resolved.family
            if resolved.premium == nil && resolved.family == nil {
                errorMessage = "Paketler şu an yüklenemedi. Lütfen internet bağlantını kontrol edip tekrar dene."
            }
        } catch {
            premiumPackage = nil
            familyPackage = nil
            errorMessage = "Paketler şu an yüklenemedi. Lütfen internet bağlantını kontrol edip tekrar dene."
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
            _ = try await RevenueCatSubscriptionPaywallService.refreshCustomerInfo()

            await refreshBackendEntitlements(customerInfo: customerInfo)

            guard EntitlementStore.shared.hasPremiumAccess else {
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
        case .premium:
            return premiumPackage
        case .family:
            return familyPackage
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

        return raw
    }

    private func refreshBackendEntitlements(customerInfo: CustomerInfo) async {
        if !AppConfig.isRevenueCatTestStoreMode {
            try? await CreditAPIService.syncIAP(.init(appUserId: Purchases.shared.appUserID))
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
