import Foundation
import RevenueCat
import Supabase

enum RevenueCatIdentityService {
    static var currentAppUserID: String {
        if PortfolioAccessMode.isEnabled {
            return OliaApp.supabase.auth.currentUser?.id.uuidString ?? "portfolio-demo-user"
        }
        return Purchases.shared.appUserID
    }

    static func syncWithCurrentSupabaseUser() async {
        guard !PortfolioAccessMode.isEnabled else { return }
        guard let user = OliaApp.supabase.auth.currentUser else { return }

        let targetAppUserId = user.id.uuidString
        guard Purchases.shared.appUserID != targetAppUserId else { return }

        do {
            let result = try await Purchases.shared.logIn(targetAppUserId)
            AppLogger.info("revenuecat.identity.login.completed", [
                "created": result.created ? "true" : "false"
            ])
        } catch {
            AppLogger.error("revenuecat.identity.login.failed", [
                "error": String(describing: type(of: error))
            ])
        }
    }

    static func resetToAnonymousIfNeeded() async {
        guard !PortfolioAccessMode.isEnabled else { return }
        guard !Purchases.shared.isAnonymous else { return }
        do {
            _ = try await Purchases.shared.logOut()
            AppLogger.info("revenuecat.identity.logout.completed", [:])
        } catch {
            AppLogger.error("revenuecat.identity.logout.failed", [
                "error": String(describing: type(of: error))
            ])
        }
    }
}
