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
        do {
            _ = try await OliaApp.supabase.auth.signUp(email: email, password: password)
            _ = try await AuthAPIService.syncCurrentUser()
            UserDefaults.standard.set(true, forKey: "luma_registration_requires_child_setup")
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
