import Foundation
import Supabase

protocol AuthSessionProviding {
    func accessToken() async throws -> String
}

enum AuthSessionProviderError: LocalizedError {
    case missingSession

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Aktif oturum bulunamadı."
        }
    }
}

final class AuthSessionProvider: AuthSessionProviding {
    static let shared = AuthSessionProvider()
    private let tokenCoordinator = AuthTokenCoordinator()

    private init() {}

    func accessToken() async throws -> String {
        try await tokenCoordinator.accessToken()
    }
}

private actor AuthTokenCoordinator {
    private var lastRefreshAttemptAt: Date?
    private let minRefreshInterval: TimeInterval = 600

    func accessToken() async throws -> String {
        let now = Date()
        if shouldAttemptRefresh(now: now) {
            _ = try? await OliaApp.supabase.auth.refreshSession()
            lastRefreshAttemptAt = now
        }

        let session = try await OliaApp.supabase.auth.session
        let token = session.accessToken
        if token.isEmpty {
            throw AuthSessionProviderError.missingSession
        }
        return token
    }

    private func shouldAttemptRefresh(now: Date) -> Bool {
        guard let lastRefreshAttemptAt else { return true }
        return now.timeIntervalSince(lastRefreshAttemptAt) >= minRefreshInterval
    }
}

