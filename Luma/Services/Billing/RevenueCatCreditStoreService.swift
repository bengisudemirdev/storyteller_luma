import Foundation
import RevenueCat

// MARK: - Offering seçimi (kredi + abonelik paywall ortak)

enum RevenueCatOfferingResolver {
    static func resolve(from offerings: Offerings, preferredKey: String?) -> Offering? {
        if let key = preferredKey,
           let configured = offerings[key] {
            return configured
        }
        if let current = offerings.current {
            return current
        }
        return offerings.all.values.first
    }
}

// MARK: - Abonelik paywall (aylık / yıllık Premium)

enum RevenueCatSubscriptionPaywallService {
    struct ResolvedPackages {
        var monthly: Package?
        var yearly: Package?
        var diagnostics: String = ""
    }

    /// Offering içinden ürünleri çöz; product, package ve entitlement adlarındaki küçük farklara toleranslıdır.
    static func fetchSubscriptionPackages() async throws -> ResolvedPackages {
        await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
        let offerings = try await Purchases.shared.offerings()

        var monthly: Package?
        var yearly: Package?
        var diagnostics: [String] = []

        diagnostics.append(
            [
                "subKey=\(AppConfig.revenueCatSubscriptionOfferingKey ?? "nil")",
                "creditsKey=\(AppConfig.revenueCatCreditsOfferingKey ?? "nil")",
                "legacyKey=\(AppConfig.revenueCatOfferingKey ?? "nil")",
                "current=\(offerings.current?.identifier ?? "nil")"
            ].joined(separator: " ")
        )

        let preferredOffering = RevenueCatOfferingResolver.resolve(
            from: offerings,
            preferredKey: AppConfig.revenueCatSubscriptionOfferingKey
        )
        let fallbackOfferings = offerings.all.values.filter { $0.identifier != preferredOffering?.identifier }

        for offering in ([preferredOffering].compactMap { $0 } + fallbackOfferings) {
            diagnostics.append("offering=\(offering.identifier) packages=\(offering.availablePackages.count)")
            for pkg in offering.availablePackages {
                let tier = RevenueCatCatalog.subscriptionTier(for: pkg)
                    ?? RevenueCatCatalog.fallbackSubscriptionTier(for: pkg)
                diagnostics.append(
                    [
                        "pkg=\(pkg.identifier)",
                        "product=\(pkg.storeProduct.productIdentifier)",
                        "category=\(String(describing: pkg.storeProduct.productCategory))",
                        "period=\(pkg.storeProduct.subscriptionPeriod.map { String(describing: $0) } ?? "nil")",
                        "tier=\(tier.map { String(describing: $0) } ?? "nil")"
                    ].joined(separator: " ")
                )

                switch tier {
                case .monthly where monthly == nil:
                    monthly = pkg
                case .yearly where yearly == nil:
                    yearly = pkg
                default:
                    continue
                }
            }

            if monthly != nil && yearly != nil {
                break
            }
        }

        diagnostics.append("resolved monthly=\(monthly?.storeProduct.productIdentifier ?? "nil") yearly=\(yearly?.storeProduct.productIdentifier ?? "nil")")
        return ResolvedPackages(monthly: monthly, yearly: yearly, diagnostics: diagnostics.joined(separator: "\n"))
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
        guard let selectedOffering = RevenueCatOfferingResolver.resolve(
            from: offerings,
            preferredKey: AppConfig.revenueCatCreditsOfferingKey
        ) else { return [] }

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
