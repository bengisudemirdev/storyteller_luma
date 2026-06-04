import Foundation
import RevenueCat

// MARK: - Offering seçimi (kredi + abonelik paywall ortak)

enum RevenueCatOfferingResolver {
    static func resolve(from offerings: Offerings) -> Offering? {
        if let key = AppConfig.revenueCatOfferingKey,
           let configured = offerings[key] {
            return configured
        }
        if let current = offerings.current {
            return current
        }
        return offerings.all.values.first
    }
}

// MARK: - Abonelik paywall (Premium / Family aylık)

enum RevenueCatSubscriptionPaywallService {
    struct ResolvedPackages {
        var premium: Package?
        var family: Package?
    }

    /// Offering içinden ürünleri çöz; product, package ve entitlement adlarındaki küçük farklara toleranslıdır.
    static func fetchSubscriptionPackages() async throws -> ResolvedPackages {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        let offerings = try await Purchases.shared.offerings()
        guard let offering = RevenueCatOfferingResolver.resolve(from: offerings) else {
            return ResolvedPackages(premium: nil, family: nil)
        }

        var premium: Package?
        var family: Package?

        for pkg in offering.availablePackages {
            switch RevenueCatCatalog.subscriptionTier(for: pkg) {
            case .premium:
                premium = pkg
            case .family:
                family = pkg
            case nil:
                continue
            }
        }

        return ResolvedPackages(premium: premium, family: family)
    }

    static func purchase(package: Package) async throws -> CustomerInfo {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        let result = try await Purchases.shared.purchase(package: package)
        return result.customerInfo
    }

    static func restorePurchases() async throws -> CustomerInfo {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        return try await Purchases.shared.restorePurchases()
    }

    static func refreshCustomerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
    }

    static func hasActiveSubscription(_ info: CustomerInfo) -> Bool {
        RevenueCatCatalog.activeSubscriptionTier(from: info) != nil
    }
}

struct RevenueCatCreditPackage: Identifiable {
    let id: String
    let config: CreditPackageConfig
    let package: Package
}

enum RevenueCatCreditStoreService {
    static func fetchPackages() async throws -> [RevenueCatCreditPackage] {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        let offerings = try await Purchases.shared.offerings()
        guard let selectedOffering = RevenueCatOfferingResolver.resolve(from: offerings) else { return [] }

        let lookup = RevenueCatCatalog.packageLookup(from: selectedOffering.availablePackages)

        // UI plani config sirasini korur; RevenueCat tarafinda productId veya package identifier ile eslesir.
        return CreditPackageConfig.all.compactMap { config in
            let byProductId = lookup.byProductId[RevenueCatCatalog.normalize(config.id)]
            let byPackageIdentifier = lookup.byPackageId[RevenueCatCatalog.normalize(config.revenueCatPackageIdentifier)]
            guard let package = byProductId ?? byPackageIdentifier else { return nil }
            return RevenueCatCreditPackage(id: config.id, config: config, package: package)
        }
    }

    static func purchase(package: RevenueCatCreditPackage) async throws -> PurchaseResultData {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        let result = try await Purchases.shared.purchase(package: package.package)
        let transactionId = result.transaction?.transactionIdentifier
            ?? result.customerInfo.latestExpirationDate?.description
            ?? UUID().uuidString

        return PurchaseResultData(
            productId: package.id,
            storeTransactionId: transactionId,
            appUserId: RevenueCatIdentityService.currentAppUserID
        )
    }

    static func restorePurchases() async throws {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        _ = try await Purchases.shared.restorePurchases()
    }
}

struct PurchaseResultData {
    let productId: String
    let storeTransactionId: String
    let appUserId: String
}
