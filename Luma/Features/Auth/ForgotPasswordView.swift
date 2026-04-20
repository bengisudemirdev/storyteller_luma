import SwiftUI
import Combine
import Supabase

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var recoveryCode = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isSendingCode = false
    @Published var isResettingPassword = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var didSendCode = false

    func sendResetEmail() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Lütfen e-posta adresini gir."
            return
        }
        guard trimmed.contains("@") else {
            errorMessage = "Geçerli bir e-posta gir."
            return
        }

        isSendingCode = true
        errorMessage = nil
        infoMessage = nil
        defer { isSendingCode = false }

        do {
            let message = try await AuthAPIService.sendForgotPassword(email: trimmed)
            didSendCode = true
            infoMessage = message
        } catch let error as APIClientError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "İstek gönderilemedi. Lütfen tekrar dene."
        }
    }

    func resetPasswordWithCode() async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let codeDigits = recoveryCode.filter(\.isNumber)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Lütfen e-posta adresini gir."
            return false
        }
        guard codeDigits.count == 8 else {
            errorMessage = "Sıfırlama kodu 8 haneli olmalı."
            return false
        }
        guard newPassword.count >= 6 else {
            errorMessage = "Yeni şifre en az 6 karakter olmalı."
            return false
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return false
        }

        isResettingPassword = true
        errorMessage = nil
        defer { isResettingPassword = false }

        do {
            try await OliaApp.supabase.auth.verifyOTP(
                email: trimmedEmail,
                token: String(codeDigits),
                type: .recovery
            )
            try await OliaApp.supabase.auth.update(user: UserAttributes(password: newPassword))
            try await OliaApp.supabase.auth.signOut()
            infoMessage = "Şifren güncellendi. Yeni şifrenle giriş yapabilirsin."
            return true
        } catch {
            errorMessage = "Kod geçersiz veya süresi dolmuş olabilir. Tekrar dene."
            return false
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var didCompleteReset = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    LumaTheme.bg,
                    LumaTheme.lightYellow,
                    LumaTheme.softBlue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("E-postana bir sıfırlama kodu gönderilir; gelen kodu ve yeni şifreni aşağıya yaz.")
                        .font(.subheadline)
                        .foregroundColor(LumaTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("E-posta")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(LumaTheme.secondaryText)
                        TextField("ornek@posta.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    Button {
                        Task { await viewModel.sendResetEmail() }
                    } label: {
                        HStack {
                            if viewModel.isSendingCode {
                                ProgressView().tint(.white)
                            }
                            Text(viewModel.isSendingCode ? "Gönderiliyor…" : "Sıfırlama kodunu gönder")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [LumaTheme.lavender, LumaTheme.lavender.opacity(0.85)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                    }
                    .disabled(viewModel.isSendingCode || viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let info = viewModel.infoMessage, !info.isEmpty {
                        Text(info)
                            .font(.footnote)
                            .foregroundColor(LumaTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if viewModel.didSendCode {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("E-postadaki kod")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(LumaTheme.secondaryText)
                            TextField("8 haneli kod", text: $viewModel.recoveryCode)
                                .textContentType(.oneTimeCode)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                            SecureField("Yeni şifre (en az 6 karakter)", text: $viewModel.newPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                            SecureField("Yeni şifre (tekrar)", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }

                        Button {
                            Task {
                                let ok = await viewModel.resetPasswordWithCode()
                                if ok {
                                    didCompleteReset = true
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isResettingPassword {
                                    ProgressView().tint(.white)
                                }
                                Text(viewModel.isResettingPassword ? "Kaydediliyor…" : "Yeni şifreyi kaydet")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [LumaTheme.lavender, LumaTheme.lavender.opacity(0.85)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(18)
                        }
                        .disabled(viewModel.isResettingPassword)
                    }

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    if didCompleteReset {
                        Button {
                            dismiss()
                        } label: {
                            Text("Giriş ekranına dön")
                                .font(.headline)
                                .foregroundColor(LumaTheme.lavender)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(18)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Şifre sıfırlama")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Kapat") {
                    dismiss()
                }
                .foregroundColor(LumaTheme.lavender)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
