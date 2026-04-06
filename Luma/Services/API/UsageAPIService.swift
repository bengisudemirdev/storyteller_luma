import Foundation

struct UsageStatusDTO: Decodable {
    let usage: UsageInfoDTO
}

struct UsageInfoDTO: Decodable {
    let date: String
    let plan: String
    let used: Int
    let limit: Int
    let remaining: Int
}

enum UsageAPIService {
    private static let client = APIClient.shared

    static func getUsage() async throws -> UsageInfoDTO {
        let endpoint = APIEndpoint(path: "/v1/usage", method: .get)
        let data: UsageStatusDTO = try await client.request(endpoint)
        return data.usage
    }
}

