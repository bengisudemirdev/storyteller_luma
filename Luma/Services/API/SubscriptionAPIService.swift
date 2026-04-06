import Foundation

struct SubscriptionStatusDataDTO: Decodable {
    let subscription: SubscriptionDTO
}

struct SubscriptionDTO: Decodable {
    let plan: String
    let status: String
    let currentPeriodEnd: String?
}

enum SubscriptionAPIService {
    private static let client = APIClient.shared

    static func getStatus() async throws -> SubscriptionDTO {
        let endpoint = APIEndpoint(path: "/v1/subscription/status", method: .get)
        let data: SubscriptionStatusDataDTO = try await client.request(endpoint)
        return data.subscription
    }
}

