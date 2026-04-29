import Foundation

struct VerifyIAPRequest: Encodable {
    let appUserId: String
    let productId: String
    let storeTransactionId: String
}

struct SyncIAPRequest: Encodable {
    let appUserId: String
}

struct CreditHistoryItem: Decodable, Identifiable {
    let id: String
    let type: String
    let amount: Int
    let balanceAfter: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case amount
        case balanceAfter = "balance_after"
        case createdAt = "created_at"
    }
}

private struct CreditHistoryResponse: Decodable {
    let items: [CreditHistoryItem]
}

enum CreditAPIService {
    private static let client = APIClient.shared

    static func fetchBalance() async throws -> CreditBalanceResponse {
        let endpoint = APIEndpoint(path: "/v1/credits/balance", method: .get)
        return try await client.request(endpoint)
    }

    static func verifyIAP(_ payload: VerifyIAPRequest) async throws {
        let endpoint = APIEndpoint(path: "/v1/iap/verify", method: .post)
        struct EmptyResponse: Decodable {}
        _ = try await client.request(endpoint, body: payload) as EmptyResponse
    }

    static func syncIAP(_ payload: SyncIAPRequest) async throws {
        let endpoint = APIEndpoint(path: "/v1/iap/sync", method: .post)
        struct EmptyResponse: Decodable {}
        _ = try await client.request(endpoint, body: payload) as EmptyResponse
    }

    static func fetchHistory(limit: Int = 20) async throws -> [CreditHistoryItem] {
        let endpoint = APIEndpoint(
            path: "/v1/credits/history",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        let response: CreditHistoryResponse = try await client.request(endpoint)
        return response.items
    }
}

