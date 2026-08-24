import Foundation
import RevenueCat

enum RevenueCatSubscriptionTier {
    case premium
    case family
}

enum RevenueCatCatalog {
    enum Credits {
        nonisolated static let productIds = CreditPackageConfig.all.map(\.id)
        nonisolated static let packageIds = CreditPackageConfig.all.map(\.revenueCatPackageIdentifier)
    }

    enum Subscription {
        nonisolated static let premiumProductIds = [
            "oliapremium",
            "oliapremium1",
            "olia_premium",
            "olia_premium_monthly",
            "com.olia.premium.monthly"
        ]

        nonisolated static let familyProductIds = [
            "olia_family_monthly",
            "oliafamily",
            "olia_family",
            "com.olia.family.monthly"
        ]

        nonisolated static let premiumPackageIds = [
            "premium",
            "premium_monthly",
            "$rc_monthly"
        ]

        nonisolated static let familyPackageIds = [
            "family",
            "family_monthly"
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

        nonisolated static let allProductIds = premiumProductIds + familyProductIds
        nonisolated static let allEntitlementIds = premiumEntitlementIds + familyEntitlementIds
    }

    nonisolated static func subscriptionTier(for package: Package) -> RevenueCatSubscriptionTier? {
        let productId = normalize(package.storeProduct.productIdentifier)
        let packageId = normalize(package.identifier)

        if isCreditPackage(productId: productId, packageId: packageId) {
            return nil
        }

        if Subscription.familyProductIds.contains(where: { normalize($0) == productId })
            || Subscription.familyPackageIds.contains(where: { normalize($0) == packageId }) {
            return .family
        }

        if Subscription.premiumProductIds.contains(where: { normalize($0) == productId })
            || Subscription.premiumPackageIds.contains(where: { normalize($0) == packageId }) {
            return .premium
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

        if productId.contains("family") || packageId.contains("family") {
            return .family
        }
        if productId.contains("premium") || packageId.contains("premium") {
            return .premium
        }
        if isSubscriptionProduct && (productId.contains("monthly") || packageId == "$rc_monthly") {
            return .premium
        }
        if isSubscriptionProduct {
            return .premium
        }
        return nil
    }

    nonisolated static func activeSubscriptionTier(from info: CustomerInfo) -> RevenueCatSubscriptionTier? {
        let activeProductIds = Set(info.activeSubscriptions.map(normalize))
        if Subscription.familyProductIds.map(normalize).contains(where: activeProductIds.contains) {
            return .family
        }
        if Subscription.premiumProductIds.map(normalize).contains(where: activeProductIds.contains) {
            return .premium
        }

        let activeEntitlementIds = Set(info.entitlements.active.keys.map(normalize))
        if Subscription.familyEntitlementIds.map(normalize).contains(where: activeEntitlementIds.contains) {
            return .family
        }
        if Subscription.premiumEntitlementIds.map(normalize).contains(where: activeEntitlementIds.contains) {
            return .premium
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
