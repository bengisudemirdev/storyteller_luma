import Foundation

struct SyncPurchaseRequest: Encodable {
    let productId: String
    let transactionId: String
    let appUserId: String
    let purchasedAtMs: Int64?
}

enum CreditAPIService {
    private static let client = APIClient.shared

    static func fetchBalance() async throws -> CreditBalanceResponse {
        let endpoint = APIEndpoint(path: "/v1/credits/balance", method: .get)
        return try await client.request(endpoint)
    }

    static func syncPurchase(_ payload: SyncPurchaseRequest) async throws {
        let endpoint = APIEndpoint(path: "/v1/credits/sync-purchase", method: .post)
        struct EmptyResponse: Decodable {}
        _ = try await client.request(endpoint, body: payload) as EmptyResponse
    }
}

