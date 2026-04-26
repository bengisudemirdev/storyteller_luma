import Foundation
import Combine

@MainActor
final class CreditStoreViewModel: ObservableObject {
    @Published private(set) var packages: [RevenueCatCreditPackage] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func loadPackages() async {
        isLoading = true
        defer { isLoading = false }
        do {
            packages = try await RevenueCatCreditStoreService.fetchPackages()
            errorMessage = nil
        } catch {
            errorMessage = error.userFacingTurkishMessage
        }
    }
}

