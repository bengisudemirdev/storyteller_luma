import SwiftUI
import Combine
import Supabase

class AuthManager: ObservableObject {
    /// Oturum kontrolü yapıldı mı? (ilk açılışta false, checkSession bitince true)
    @Published var isSessionChecked: Bool = false
    @Published var isAuthenticated: Bool = false

    init() { checkSession() }

    func checkSession() {
        Task { @MainActor in
            let session = try? await OliaApp.supabase.auth.session
            self.isAuthenticated = (session != nil)
            if session != nil {
                try? await AuthAPIService.syncCurrentUser()
            }
            self.isSessionChecked = true
            for await (_, session) in OliaApp.supabase.auth.authStateChanges {
                self.isAuthenticated = (session != nil)
                if session != nil {
                    try? await AuthAPIService.syncCurrentUser()
                }
            }
        }
    }
}
