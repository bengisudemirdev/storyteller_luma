import Foundation
import RevenueCat

struct RevenueCatCreditPackage: Identifiable {
    let id: String
    let config: CreditPackageConfig
    let package: Package
}

enum RevenueCatCreditStoreService {
    static func fetchPackages() async throws -> [RevenueCatCreditPackage] {
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else { return [] }

        let packageMap = Dictionary(uniqueKeysWithValues: current.availablePackages.map {
            ($0.storeProduct.productIdentifier, $0)
        })

        return CreditPackageConfig.all.compactMap { config in
            guard let package = packageMap[config.id] else { return nil }
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
            transactionId: transactionId,
            appUserId: Purchases.shared.appUserID,
            purchasedAtMs: result.transaction.map { Int64($0.purchaseDate.timeIntervalSince1970 * 1000) }
        )
    }

    static func restorePurchases() async throws {
        _ = try await Purchases.shared.restorePurchases()
    }
}

struct PurchaseResultData {
    let productId: String
    let transactionId: String
    let appUserId: String
    let purchasedAtMs: Int64?
}

