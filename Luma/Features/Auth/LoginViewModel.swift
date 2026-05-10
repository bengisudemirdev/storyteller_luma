import Foundation
import Supabase
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn() async -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen e-posta ve şifrenizi girin."
            return false
        }
        isLoading = true
        errorMessage = nil
        do {
            try await OliaApp.supabase.auth.signIn(email: email, password: password)
            _ = try await AuthAPIService.syncCurrentUser(force: true)
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
            isLoading = false
            return true
        } catch {
            errorMessage = "E-posta veya şifre hatalı. Lütfen tekrar dene."
            isLoading = false
            return false
        }
    }
}
