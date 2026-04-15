import Foundation

struct AuthMeDataDTO: Decodable {
    let user: AuthMeUserDTO
}

struct AuthMeUserDTO: Decodable {
    let id: UUID
    let email: String?
}

enum AuthAPIService {
    private static let syncCoordinator = AuthMeSyncCoordinator()

    static func syncCurrentUser(force: Bool = false) async throws -> AuthMeUserDTO {
        try await syncCoordinator.sync(force: force)
    }
}

private enum AuthMeSyncError: LocalizedError {
    case throttled

    var errorDescription: String? {
        switch self {
        case .throttled:
            return "Kullanıcı eşitlemesi kısa süreliğine ertelendi."
        }
    }
}

private actor AuthMeSyncCoordinator {
    private var cachedUser: AuthMeUserDTO?
    private var lastSyncedAt: Date?
    private var lastAttemptAt: Date?
    private var inFlightTask: Task<AuthMeUserDTO, Error>?
    private let cooldown: TimeInterval = 60
    private let retryBackoffAfterFailure: TimeInterval = 20

    func sync(force: Bool) async throws -> AuthMeUserDTO {
        if let inFlightTask {
            return try await inFlightTask.value
        }

        if !force,
           let cachedUser,
           let lastSyncedAt,
           Date().timeIntervalSince(lastSyncedAt) < cooldown {
            return cachedUser
        }

        if !force,
           let lastAttemptAt,
           Date().timeIntervalSince(lastAttemptAt) < retryBackoffAfterFailure {
            if let cachedUser {
                return cachedUser
            }
            throw AuthMeSyncError.throttled
        }

        lastAttemptAt = Date()
        let task = Task<AuthMeUserDTO, Error> {
            let endpoint = APIEndpoint(path: "/v1/auth/me", method: .post)
            let data: AuthMeDataDTO = try await APIClient.shared.request(endpoint)
            return data.user
        }
        inFlightTask = task

        do {
            let user = try await task.value
            cachedUser = user
            lastSyncedAt = Date()
            inFlightTask = nil
            return user
        } catch {
            inFlightTask = nil
            throw error
        }
    }
}

