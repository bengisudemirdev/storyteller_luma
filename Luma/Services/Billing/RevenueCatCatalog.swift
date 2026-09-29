import Foundation
import RevenueCat

enum RevenueCatSubscriptionTier {
    case monthly
    case yearly
}

enum RevenueCatCatalog {
    enum Credits {
        nonisolated static let productIds = CreditPackageConfig.all.map(\.id)
        nonisolated static let packageIds = CreditPackageConfig.all.map(\.revenueCatPackageIdentifier)
    }

    enum Subscription {
        nonisolated static let monthlyProductIds = [
            "oliapremium",
            "oliapremium1",
            "olia_premium",
            "olia_premium_monthly",
            "com.olia.premium.monthly"
        ]

        nonisolated static let yearlyProductIds = [
            "oliapremium_yearly"
        ]

        nonisolated static let monthlyPackageIds = [
            "premium",
            "premium_monthly",
            "$rc_monthly"
        ]

        nonisolated static let yearlyPackageIds = [
            "yearly",
            "premium_yearly",
            "$rc_annual"
        ]

        nonisolated static let premiumEntitlementIds = [
            "premium",
            "oliapremium",
            "olia_premium",
            "lumapremium"
        ]

        nonisolated static let familyEntitlementIds = [
            "family",
            "olia_family",
            "oliafamily"
        ]

        nonisolated static let allProductIds = monthlyProductIds + yearlyProductIds
        nonisolated static let allEntitlementIds = premiumEntitlementIds + familyEntitlementIds
    }

    nonisolated static func subscriptionTier(for package: Package) -> RevenueCatSubscriptionTier? {
        let productId = normalize(package.storeProduct.productIdentifier)
        let packageId = normalize(package.identifier)

        if isCreditPackage(productId: productId, packageId: packageId) {
            return nil
        }

        if Subscription.yearlyProductIds.contains(where: { normalize($0) == productId })
            || Subscription.yearlyPackageIds.contains(where: { normalize($0) == packageId }) {
            return .yearly
        }

        if Subscription.monthlyProductIds.contains(where: { normalize($0) == productId })
            || Subscription.monthlyPackageIds.contains(where: { normalize($0) == packageId }) {
            return .monthly
        }

        return nil
    }

    nonisolated static func fallbackSubscriptionTier(for package: Package) -> RevenueCatSubscriptionTier? {
        let productId = normalize(package.storeProduct.productIdentifier)
        let packageId = normalize(package.identifier)
        let isSubscriptionProduct = package.storeProduct.productCategory == .subscription
            || package.storeProduct.subscriptionPeriod != nil

        if isCreditPackage(productId: productId, packageId: packageId) {
            return nil
        }

        if productId.contains("year") || packageId.contains("annual") || packageId.contains("year") {
            return .yearly
        }
        if isSubscriptionProduct && package.storeProduct.subscriptionPeriod?.unit == .year {
            return .yearly
        }
        if isSubscriptionProduct && (productId.contains("monthly") || packageId == "$rc_monthly") {
            return .monthly
        }
        if isSubscriptionProduct && (productId.contains("premium") || packageId.contains("premium")) {
            return .monthly
        }
        return nil
    }

    nonisolated static func activeSubscriptionTier(from info: CustomerInfo) -> RevenueCatSubscriptionTier? {
        let activeProductIds = Set(info.activeSubscriptions.map(normalize))
        if Subscription.yearlyProductIds.map(normalize).contains(where: activeProductIds.contains) {
            return .yearly
        }
        if Subscription.monthlyProductIds.map(normalize).contains(where: activeProductIds.contains) {
            return .monthly
        }

        let activeEntitlementIds = Set(info.entitlements.active.keys.map(normalize))
        if Subscription.familyEntitlementIds.map(normalize).contains(where: activeEntitlementIds.contains) {
            return .monthly
        }
        if Subscription.premiumEntitlementIds.map(normalize).contains(where: activeEntitlementIds.contains) {
            return .monthly
        }

        return nil
    }

    nonisolated static func packageLookup(from packages: [Package]) -> (byProductId: [String: Package], byPackageId: [String: Package]) {
        var byProductId: [String: Package] = [:]
        var byPackageId: [String: Package] = [:]

        for package in packages {
            // Keep the first package for duplicate ids so a duplicated RevenueCat setup cannot crash the paywall.
            let productId = normalize(package.storeProduct.productIdentifier)
            let packageId = normalize(package.identifier)
            if byProductId[productId] == nil {
                byProductId[productId] = package
            }
            if byPackageId[packageId] == nil {
                byPackageId[packageId] = package
            }
        }

        return (byProductId, byPackageId)
    }

    nonisolated static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private nonisolated static func isCreditPackage(productId: String, packageId: String) -> Bool {
        if productId.contains("credit") || productId.contains("credits") {
            return true
        }
        return Credits.productIds.map(normalize).contains(productId)
    }
}
