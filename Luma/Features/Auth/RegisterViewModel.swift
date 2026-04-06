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
        do {
            _ = try await OliaApp.supabase.auth.signUp(email: email, password: password)
            _ = try await AuthAPIService.syncCurrentUser()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
