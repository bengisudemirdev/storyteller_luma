import Foundation
import Combine

@MainActor
final class CreditBalanceViewModel: ObservableObject {
    static let shared = CreditBalanceViewModel()

    @Published private(set) var balance: Int = 0
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastUpdatedAt: Date?
    @Published var errorMessage: String?

    private init() {}

    func refreshBalance() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let response = try await CreditAPIService.fetchBalance()
            balance = response.balance
            lastUpdatedAt = Self.parseDate(response.updatedAt) ?? Date()
            errorMessage = nil
        } catch {
            errorMessage = error.userFacingTurkishMessage
        }
    }

    func hasCredits(required: Int) -> Bool {
        balance >= required
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if let date = ISO8601DateFormatter().date(from: value) { return date }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}

