import Foundation

struct AuthMeDataDTO: Decodable {
    let user: AuthMeUserDTO
}

struct AuthMeUserDTO: Decodable {
    let id: UUID
    let email: String?
}

enum AuthAPIService {
    private static let client = APIClient.shared

    static func syncCurrentUser() async throws -> AuthMeUserDTO {
        let endpoint = APIEndpoint(path: "/v1/auth/me", method: .post)
        let data: AuthMeDataDTO = try await client.request(endpoint)
        return data.user
    }
}

