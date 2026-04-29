import Foundation
import Combine
import RevenueCat

@MainActor
final class PurchaseViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case purchasing
        case syncing
        case success
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    var isBusy: Bool {
        switch state {
        case .purchasing, .syncing:
            return true
        case .idle, .success, .failed:
            return false
        }
    }

    func purchase(_ package: RevenueCatCreditPackage) async {
        state = .purchasing
        do {
            let result = try await RevenueCatCreditStoreService.purchase(package: package)
            state = .syncing
            try await CreditAPIService.verifyIAP(
                .init(
                    appUserId: result.appUserId,
                    productId: result.productId,
                    storeTransactionId: result.storeTransactionId
                )
            )
            try await CreditAPIService.syncIAP(.init(appUserId: result.appUserId))
            await CreditBalanceViewModel.shared.refreshBalance()
            state = .success
        } catch {
            state = .failed(error.userFacingTurkishMessage)
        }
    }

    func restore() async {
        state = .syncing
        do {
            try await RevenueCatCreditStoreService.restorePurchases()
            try await CreditAPIService.syncIAP(.init(appUserId: Purchases.shared.appUserID))
            await CreditBalanceViewModel.shared.refreshBalance()
            state = .success
        } catch {
            state = .failed(error.userFacingTurkishMessage)
        }
    }

    func resetState() {
        state = .idle
    }
}

