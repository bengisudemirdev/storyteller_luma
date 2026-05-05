import Foundation
import Supabase

/// POST /v1/children — snake_case body (CodingKeys)
struct CreateChildRequestDTO: Encodable {
    let name: String
    let age: Int?
    let profile: String?
    let avatarEmoji: String?
    let interests: [String]?
    let fears: [String]?

    enum CodingKeys: String, CodingKey {
        case name, age, profile, interests, fears
        case avatarEmoji = "avatar_emoji"
    }
}

/// PATCH /v1/children/:id
struct UpdateChildRequestDTO: Encodable {
    let name: String?
    let age: Int?
    let profile: String?
    let avatarEmoji: String?
    let interests: [String]?
    let fears: [String]?

    enum CodingKeys: String, CodingKey {
        case name, age, profile, interests, fears
        case avatarEmoji = "avatar_emoji"
    }
}

struct ChildDataDTO: Decodable {
    let child: ChildModel

    private enum CodingKeys: String, CodingKey {
        case child
    }

    /// Sunucu `{ data: { child: {...} } }` veya `{ data: { ...çocuk alanları düz } }` dönebilir.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.child) {
            self.child = try c.decode(ChildModel.self, forKey: .child)
        } else {
            self.child = try ChildModel(from: decoder)
        }
    }
}

struct ChildrenDataDTO: Decodable {
    let children: [ChildModel]
}

enum ChildrenAPIService {
    private static let client = APIClient.shared

    private enum SessionGuardError: LocalizedError {
        case missingSession

        var errorDescription: String? {
            switch self {
            case .missingSession:
                return "Oturum bulunamadı. Lütfen yeniden giriş yapın."
            }
        }
    }

    static func fetchChildren() async throws -> [ChildModel] {
        let endpoint = APIEndpoint(path: "/v1/children", method: .get)
        let data: ChildrenDataDTO = try await client.request(endpoint)
        return data.children
    }

    static func createChild(
        name: String,
        age: Int?,
        profile: String? = nil,
        avatarEmoji: String?,
        interests: [String]?,
        fears: [String]?
    ) async throws -> ChildModel {
        try await ensureValidSession()

        let endpoint = APIEndpoint(path: "/v1/children", method: .post)
        let body = CreateChildRequestDTO(
            name: name,
            age: age,
            profile: profile,
            avatarEmoji: avatarEmoji,
            interests: interests,
            fears: fears
        )
        let data: ChildDataDTO = try await client.request(endpoint, body: body)
        return data.child
    }

    static func updateChild(
        id: UUID,
        name: String?,
        age: Int?,
        profile: String? = nil,
        avatarEmoji: String?,
        interests: [String]?,
        fears: [String]?
    ) async throws -> ChildModel {
        let endpoint = APIEndpoint(path: "/v1/children/\(id.uuidString)", method: .patch)
        let body = UpdateChildRequestDTO(
            name: name,
            age: age,
            profile: profile,
            avatarEmoji: avatarEmoji,
            interests: interests,
            fears: fears
        )
        let data: ChildDataDTO = try await client.request(endpoint, body: body)
        return data.child
    }

    static func deleteChild(id: UUID) async throws {
        let endpoint = APIEndpoint(path: "/v1/children/\(id.uuidString)", method: .delete)
        let _: ChildDataDTO = try await client.request(endpoint)
    }

    private static func ensureValidSession() async throws {
        let session: Session
        do {
            session = try await OliaApp.supabase.auth.session
        } catch {
            throw SessionGuardError.missingSession
        }

        if session.isExpired {
            _ = try await OliaApp.supabase.auth.refreshSession()
        }
    }
}
