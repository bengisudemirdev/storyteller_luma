import Foundation
import Supabase
import Combine

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signUp() async -> Bool {
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Lütfen ad soyad alanını doldurun."
            return false
        }
        guard email.contains("@"), email.contains(".") else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "Şifreler birbiriyle eşleşmiyor."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Şifreniz en az 6 karakter olmalıdır."
            return false
        }
        isLoading = true
        errorMessage = nil
        // Oturum açılır açılmaz authStateChanges ana ekranı gösterebilir; bayrak önce yazılmalı.
        UserDefaults.standard.set(true, forKey: "luma_registration_requires_child_setup")
        do {
            _ = try await OliaApp.supabase.auth.signUp(email: email, password: password)
        } catch {
            UserDefaults.standard.set(false, forKey: "luma_registration_requires_child_setup")
            errorMessage = signupFailureMessage(for: error)
            isLoading = false
            return false
        }
        do {
            _ = try await AuthAPIService.syncCurrentUser(force: true)
            await RevenueCatIdentityService.syncWithCurrentSupabaseUser()
            if !PortfolioAccessMode.isEnabled && !AppConfig.isRevenueCatTestStoreMode {
                try? await CreditAPIService.syncIAP(.init(appUserId: RevenueCatIdentityService.currentAppUserID))
            }
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
        } catch {
            UserDefaults.standard.set(false, forKey: "luma_registration_requires_child_setup")
            try? await OliaApp.supabase.auth.signOut()
            errorMessage = error.userFacingTurkishMessage
            isLoading = false
            return false
        }
        isLoading = false
        return true
    }

    private func signupFailureMessage(for error: Error) -> String {
        let fallback = error.userFacingTurkishMessage
        let raw = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return fallback }

        let lower = raw.lowercased()

        if lower.contains("already registered")
            || lower.contains("user already registered")
            || lower.contains("email already")
            || lower.contains("already exists")
            || lower.contains("duplicate key")
            || lower.contains("already in use") {
            return "Bu e-posta ile zaten bir hesap var. Giriş yapabilir veya şifreni sıfırlayabilirsin."
        }

        if lower.contains("invalid email") || lower.contains("email format") {
            return "E-posta adresi geçersiz görünüyor. Lütfen doğru formatta bir adres girin."
        }

        if lower.contains("password")
            && (lower.contains("weak") || lower.contains("short") || lower.contains("at least")) {
            return "Şifre güvenli değil. En az 6 karakter, mümkünse harf ve rakam içeren bir şifre seç."
        }

        if lower.contains("rate limit") || lower.contains("too many requests") {
            return "Kısa sürede çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene."
        }

        if lower.contains("network") || lower.contains("timeout") || lower.contains("connection") {
            return "Kayıt sırasında bağlantı sorunu oluştu. İnternetini kontrol edip tekrar dene."
        }

        // Kullanıcıya sebebi görünür kılmak için ham mesajı da aktar.
        return "Kayıt oluşturulamadı: \(raw)"
    }
}
