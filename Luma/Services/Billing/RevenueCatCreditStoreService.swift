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
    static let premiumProductIdentifier = "oliapremium"
    static let familyProductIdentifier = "olia_family_monthly"

    private static let premiumPackageIdentifier = "premium_monthly"
    private static let familyPackageIdentifier = "family_monthly"

    struct ResolvedPackages {
        var premium: Package?
        var family: Package?
    }

    /// Offering içinden ürünleri çöz; önce `productIdentifier`, sonra RevenueCat package identifier ile eşleştir.
    static func fetchSubscriptionPackages() async throws -> ResolvedPackages {
        let offerings = try await Purchases.shared.offerings()
        guard let offering = RevenueCatOfferingResolver.resolve(from: offerings) else {
            return ResolvedPackages(premium: nil, family: nil)
        }

        var premium: Package?
        var family: Package?

        for pkg in offering.availablePackages {
            let pid = pkg.storeProduct.productIdentifier.lowercased()
            let rcId = pkg.identifier.lowercased()

            if pid == premiumProductIdentifier.lowercased()
                || rcId == premiumPackageIdentifier.lowercased() {
                premium = pkg
            }
            if pid == familyProductIdentifier.lowercased()
                || rcId == familyPackageIdentifier.lowercased() {
                family = pkg
            }
        }

        return ResolvedPackages(premium: premium, family: family)
    }

    static func purchase(package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        return result.customerInfo
    }

    static func restorePurchases() async throws -> CustomerInfo {
        try await Purchases.shared.restorePurchases()
    }

    static func refreshCustomerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
    }

    static func hasActiveSubscription(_ info: CustomerInfo) -> Bool {
        let activeIds = Set(info.activeSubscriptions.map { $0.lowercased() })
        if activeIds.contains(premiumProductIdentifier.lowercased())
            || activeIds.contains(familyProductIdentifier.lowercased()) {
            return true
        }
        if info.entitlements.active["oliapremium"] != nil { return true }
        if info.entitlements.active["premium"] != nil { return true }
        if info.entitlements.active["lumapremium"] != nil { return true }
        return false
    }
}

struct RevenueCatCreditPackage: Identifiable {
    let id: String
    let config: CreditPackageConfig
    let package: Package
}

enum RevenueCatCreditStoreService {
    static func fetchPackages() async throws -> [RevenueCatCreditPackage] {
        let offerings = try await Purchases.shared.offerings()
        guard let selectedOffering = RevenueCatOfferingResolver.resolve(from: offerings) else { return [] }

        let packagesByProductId = Dictionary(
            uniqueKeysWithValues: selectedOffering.availablePackages.map {
                ($0.storeProduct.productIdentifier, $0)
            }
        )
        let packagesByIdentifier = Dictionary(
            uniqueKeysWithValues: selectedOffering.availablePackages.map {
                ($0.identifier.lowercased(), $0)
            }
        )

        // UI plani config sirasini korur; RevenueCat tarafinda productId veya package identifier ile eslesir.
        return CreditPackageConfig.all.compactMap { config in
            let byProductId = packagesByProductId[config.id]
            let byPackageIdentifier = packagesByIdentifier[config.revenueCatPackageIdentifier.lowercased()]
            guard let package = byProductId ?? byPackageIdentifier else { return nil }
            return RevenueCatCreditPackage(id: config.id, config: config, package: package)
        }
    }

    static func purchase(package: RevenueCatCreditPackage) async throws -> PurchaseResultData {
        let result = try await Purchases.shared.purchase(package: package.package)
        let transactionId = result.transaction?.transactionIdentifier
            ?? result.customerInfo.latestExpirationDate?.description
            ?? UUID().uuidString

        return PurchaseResultData(
            productId: package.id,
            storeTransactionId: transactionId,
            appUserId: Purchases.shared.appUserID
        )
    }

    static func restorePurchases() async throws {
        _ = try await Purchases.shared.restorePurchases()
    }
}

struct PurchaseResultData {
    let productId: String
    let storeTransactionId: String
    let appUserId: String
}

