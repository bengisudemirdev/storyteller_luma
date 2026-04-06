import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isAnimate = false
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
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

                Circle()
                    .fill(LumaTheme.lavender.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -150, y: -350)

                VStack(spacing: 25) {
                    Spacer()

                    VStack(spacing: 10) {
                        Image("lumalogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .shadow(color: LumaTheme.lavender.opacity(0.3), radius: 20, x: 0, y: 10)
                            .scaleEffect(isAnimate ? 1.05 : 1.0)

                        Text(AppBrand.displayName)
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(LumaTheme.text)

                        Text(AppBrand.subtitle)
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(LumaTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 15) {
                        customInputField(title: "E-posta", text: $viewModel.email, icon: "envelope.fill")
                        customPasswordField(title: "Şifre", text: $viewModel.password, isVisible: $isPasswordVisible)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: {}) {
                            Text("Şifremi Unuttum")
                                .font(.caption)
                                .foregroundColor(LumaTheme.lavender)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(25)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    .padding(.horizontal, 30)

                    Button(action: {
                        Task {
                            _ = await viewModel.signIn()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white).padding(.trailing, 5)
                            }
                            Text(viewModel.isLoading ? "Giriş Yapılıyor..." : "Masala Başla")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [LumaTheme.lavender, LumaTheme.lavender.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(20)
                        .shadow(color: LumaTheme.lavender.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 30)
                    .disabled(viewModel.isLoading)

                    NavigationLink(destination: RegisterView()) {
                        HStack {
                            Text("Henüz bir hesabın yok mu?")
                                .foregroundColor(LumaTheme.secondaryText)
                            Text("Kayıt Ol")
                                .fontWeight(.bold)
                                .foregroundColor(LumaTheme.lavender)
                        }
                        .font(.footnote)
                    }
                    .padding(.top, 10)

                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { isAnimate = true }
            }
        }
    }

    func customInputField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(LumaTheme.lavender)
                .frame(width: 30)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(title).foregroundColor(LumaTheme.text.opacity(0.7))
                }
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
            Image(systemName: "lock.fill")
                .foregroundColor(LumaTheme.lavender)
                .frame(width: 30)
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

#Preview { LoginView() }
