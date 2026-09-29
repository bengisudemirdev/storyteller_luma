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
            self.isAuthenticated = Self.representsLoggedInUser(session)
            // Yerel oturum okunur okunmaz arayüz açılır. Ağ eşitlemesi (profil, RevenueCat, haklar) arka planda çalışır:
            // eskiden bunu beklerken backend yavaş/kapalıysa uygulama dakikalarca açılış ekranında kalıyordu.
            self.isSessionChecked = true
            if Self.representsLoggedInUser(session) {
                Task { @MainActor [weak self] in
                    await self?.syncCurrentUserIfNeeded(force: true)
                }
            }
            for await (_, session) in OliaApp.supabase.auth.authStateChanges {
                self.isAuthenticated = Self.representsLoggedInUser(session)
                if Self.representsLoggedInUser(session) {
                    await self.syncCurrentUserIfNeeded()
                } else {
                    await RevenueCatIdentityService.resetToAnonymousIfNeeded()
                }
            }
        }
    }

    /// `emitLocalSessionAsInitialSession` açıkken süresi dolmuş yerel JWT gelebilir; refresh token varsa oturumu koru (SDK yeniler).
    private static func representsLoggedInUser(_ session: Session?) -> Bool {
        guard let session else { return false }
        if session.isExpired {
            return !session.refreshToken.isEmpty
        }
        return true
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
            await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
            if !PortfolioAccessMode.isEnabled && !AppConfig.isRevenueCatTestStoreMode {
                try? await CreditAPIService.syncIAP(.init(appUserId: RevenueCatIdentityService.currentAppUserID))
            }
            lastAuthSyncAt = Date()
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
        } catch {
            // Sessiz geç: auth state UI için kritik, profil sync kısa süre sonra tekrar denenir.
        }
    }
}
