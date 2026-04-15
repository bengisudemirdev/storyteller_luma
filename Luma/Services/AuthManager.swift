import SwiftUI
import Combine
import Supabase

class AuthManager: ObservableObject {
    /// Oturum kontrolü yapıldı mı? (ilk açılışta false, checkSession bitince true)
    @Published var isSessionChecked: Bool = false
    @Published var isAuthenticated: Bool = false
    private var lastAuthSyncAt: Date?
    private let minSyncInterval: TimeInterval = 30

    init() { checkSession() }

    func checkSession() {
        Task { @MainActor in
            let session = try? await OliaApp.supabase.auth.session
            self.isAuthenticated = (session != nil)
            if session != nil {
                await self.syncCurrentUserIfNeeded(force: true)
            }
            self.isSessionChecked = true
            for await (_, session) in OliaApp.supabase.auth.authStateChanges {
                self.isAuthenticated = (session != nil)
                if session != nil {
                    await self.syncCurrentUserIfNeeded()
                }
            }
        }
    }

    @MainActor
    private func syncCurrentUserIfNeeded(force: Bool = false) async {
        if !force,
           let lastAuthSyncAt,
           Date().timeIntervalSince(lastAuthSyncAt) < minSyncInterval {
            return
        }
        do {
            _ = try await AuthAPIService.syncCurrentUser(force: force)
            lastAuthSyncAt = Date()
        } catch {
            // Sessiz geç: auth state UI için kritik, profil sync kısa süre sonra tekrar denenir.
        }
    }
}
