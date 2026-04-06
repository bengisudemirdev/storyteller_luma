import SwiftUI
import Supabase

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
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
                VStack(spacing: 25) {
                    VStack(spacing: 10) {
                        Text("Aramıza Katıl")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(LumaTheme.text)
                        Text(AppBrand.subtitle)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(LumaTheme.secondaryText)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 15) {
                        customInputField(title: "Ad Soyad", text: $viewModel.fullName, icon: "person.fill")
                        customInputField(title: "E-posta", text: $viewModel.email, icon: "envelope.fill")
                        customPasswordField(title: "Şifre", text: $viewModel.password, isVisible: $isPasswordVisible)
                        customPasswordField(title: "Şifre Tekrar", text: $viewModel.confirmPassword, isVisible: $isConfirmPasswordVisible)
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(25)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    .padding(.horizontal, 30)

                    Button(action: {
                        Task { _ = await viewModel.signUp() }
                    }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).padding(.trailing, 5) }
                            Text(viewModel.isLoading ? "Kaydediliyor..." : "Hesap Oluştur").font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LumaTheme.lavender)
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
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }

    func customInputField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(LumaTheme.lavender).frame(width: 30)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty { Text(title).foregroundColor(LumaTheme.text.opacity(0.7)) }
                TextField("", text: text).autocapitalization(.none).foregroundColor(LumaTheme.text)
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
                    TextField("", text: text).autocapitalization(.none).foregroundColor(LumaTheme.text)
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
