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

    private init() {}

    func accessToken() async throws -> String {
        // Access token süresi dolduysa yenilemeyi dene (başarısızsa mevcut session ile devam).
        _ = try? await OliaApp.supabase.auth.refreshSession()
        let session = try await OliaApp.supabase.auth.session
        let token = session.accessToken
        if token.isEmpty {
            throw AuthSessionProviderError.missingSession
        }
        return token
    }
}

