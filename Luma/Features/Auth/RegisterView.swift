import SwiftUI
import Supabase

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var shouldShowChildSetup = false
    @AppStorage("luma_registration_requires_child_setup") private var registrationRequiresChildSetup = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [LumaTheme.bg, LumaTheme.lightYellow, LumaTheme.softBlue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text("Hesap Oluştur")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(LumaTheme.text)
                        Text("1/2 • Ebeveyn bilgileri")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(LumaTheme.lavender)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.8))
                            )
                        Text("Bu adımı tamamladıktan sonra çocuğunuzun profilini ekleyip kaydı bitireceğiz.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(LumaTheme.secondaryText)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 28)

                    VStack(spacing: 14) {
                        customInputField(title: "Ad Soyad", text: $viewModel.fullName, icon: "person.fill")
                        customInputField(title: "E-posta", text: $viewModel.email, icon: "envelope.fill")
                        customPasswordField(title: "Şifre", text: $viewModel.password, isVisible: $isPasswordVisible)
                        customPasswordField(title: "Şifre Tekrar", text: $viewModel.confirmPassword, isVisible: $isConfirmPasswordVisible)
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.top, 2)
                        }
                    }
                    .padding(25)
                    .background(Color.white.opacity(0.76))
                    .cornerRadius(28)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.55), lineWidth: 1))
                    .shadow(color: LumaTheme.lavender.opacity(0.12), radius: 14, x: 0, y: 8)
                    .padding(.horizontal, 30)

                    Button(action: {
                        Task {
                            let didSignUp = await viewModel.signUp()
                            if didSignUp {
                                registrationRequiresChildSetup = true
                                shouldShowChildSetup = true
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).padding(.trailing, 5) }
                            Text(viewModel.isLoading ? "Kaydediliyor..." : "Devam Et")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [LumaTheme.lavender, LumaTheme.lavender.opacity(0.82)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: LumaTheme.lavender.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 30)
                    .disabled(viewModel.isLoading)

                    Button(action: { dismiss() }) {
                        HStack {
                            Text("Zaten bir hesabın var mı?").foregroundColor(LumaTheme.secondaryText)
                            Text("Giriş Yap").fontWeight(.bold).foregroundColor(LumaTheme.lavender)
                        }
                        .font(.footnote)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $shouldShowChildSetup) {
            RegistrationChildSetupView {
                registrationRequiresChildSetup = false
                dismiss()
            }
        }
    }

    func customInputField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(LumaTheme.lavender).frame(width: 30)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty { Text(title).foregroundColor(LumaTheme.text.opacity(0.7)) }
                TextField("", text: text)
                    .textInputAutocapitalization(.never)
                    .foregroundColor(LumaTheme.text)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    func customPasswordField(title: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: "lock.fill").foregroundColor(LumaTheme.lavender).frame(width: 30)
            if isVisible.wrappedValue {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty { Text(title).foregroundColor(LumaTheme.text.opacity(0.7)) }
                    TextField("", text: text)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(LumaTheme.text)
                }
            } else {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty { Text(title).foregroundColor(LumaTheme.text.opacity(0.7)) }
                    SecureField("", text: text).foregroundColor(LumaTheme.text)
                }
            }
            Spacer()
            Button(action: { isVisible.wrappedValue.toggle() }) {
                Image(systemName: isVisible.wrappedValue ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(LumaTheme.lavender.opacity(0.8))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview { RegisterView() }
