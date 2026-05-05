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
        case cancelled
        case syncFailed(String)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    var isBusy: Bool {
        switch state {
        case .purchasing, .syncing:
            return true
        case .idle, .success, .cancelled, .syncFailed, .failed:
            return false
        }
    }

    func purchase(_ package: RevenueCatCreditPackage) async {
        state = .purchasing
        do {
            let result = try await RevenueCatCreditStoreService.purchase(package: package)
            state = .syncing
            if AppConfig.isRevenueCatTestStoreMode {
                // RevenueCat Test Store transaction'ları Apple verify hattına girmez.
                // Bu modda satın alımı başarılı kabul edip bakiyeyi backend'den yeniden çekeriz.
                await CreditBalanceViewModel.shared.refreshBalance()
                state = .success
                return
            }
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
        } catch let error as Error where error.isPurchaseCancelledError {
            state = .cancelled
        } catch let error as Error where error.isCancellationError {
            state = .cancelled
        } catch {
            if state == .syncing {
                state = .syncFailed(error.userFacingTurkishMessage)
                return
            }
            state = .failed(error.userFacingTurkishMessage)
        }
    }

    func syncPurchasedCredits() async {
        state = .syncing
        do {
            if !AppConfig.isRevenueCatTestStoreMode {
                try await CreditAPIService.syncIAP(.init(appUserId: Purchases.shared.appUserID))
            }
            await CreditBalanceViewModel.shared.refreshBalance()
            state = .success
        } catch {
            state = .syncFailed(error.userFacingTurkishMessage)
        }
    }

    func restore() async {
        state = .syncing
        do {
            try await RevenueCatCreditStoreService.restorePurchases()
            await syncPurchasedCredits()
        } catch {
            state = .failed(error.userFacingTurkishMessage)
        }
    }

    func resetState() {
        state = .idle
    }
}

private extension Error {
    var isPurchaseCancelledError: Bool {
        let nsError = self as NSError
        return nsError.domain == "RevenueCat.ErrorCode"
            && nsError.code == ErrorCode.purchaseCancelledError.rawValue
    }

    var isCancellationError: Bool {
        self is CancellationError
    }
}

