import SwiftUI
import UIKit

struct LoginView: View {
    private enum LoginFocusField: Hashable {
        case email
        case password
    }

    @StateObject private var viewModel = LoginViewModel()
    @State private var isAnimate = false
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: LoginFocusField?

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
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }

                Circle()
                    .fill(LumaTheme.lavender.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -150, y: -350)
                    .allowsHitTesting(false)

                VStack(spacing: 25) {
                    Spacer()

                    VStack(spacing: 10) {
                        brandIconView
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }

                    VStack(spacing: 15) {
                        customInputField(title: "E-posta", text: $viewModel.email, icon: "envelope.fill", field: .email)
                        customPasswordField(title: "Şifre", text: $viewModel.password, isVisible: $isPasswordVisible, field: .password)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        NavigationLink {
                            ForgotPasswordView()
                        } label: {
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
                            dismissKeyboard()
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
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            dismissKeyboard()
                        }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { isAnimate = true }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Kapat") {
                        dismissKeyboard()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    @ViewBuilder
    private var brandIconView: some View {
        if UIImage(named: "lumalogo") != nil {
            Image("lumalogo")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .shadow(color: LumaTheme.lavender.opacity(0.3), radius: 20, x: 0, y: 10)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [LumaTheme.lavender.opacity(0.9), LumaTheme.softBlue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 180, height: 180)
            .shadow(color: LumaTheme.lavender.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func customInputField(title: String, text: Binding<String>, icon: String, field: LoginFocusField) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(LumaTheme.lavender)
                .frame(width: 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = field
                }

            TextField("", text: text, prompt: lumaPrompt(title))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lumaInputText()
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
        }
        .lumaInputBox(focused: focusedField == field)
    }

    private func customPasswordField(title: String, text: Binding<String>, isVisible: Binding<Bool>, field: LoginFocusField) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(LumaTheme.lavender)
                .frame(width: 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = field
                }

            Group {
                if isVisible.wrappedValue {
                    TextField("", text: text, prompt: lumaPrompt(title))
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lumaInputText()
                        .focused($focusedField, equals: field)
                        .submitLabel(.go)
                        .onSubmit {
                            Task {
                                dismissKeyboard()
                                _ = await viewModel.signIn()
                            }
                        }
                } else {
                    SecureField("", text: text, prompt: lumaPrompt(title))
                        .textContentType(.password)
                        .lumaInputText()
                        .focused($focusedField, equals: field)
                        .submitLabel(.go)
                        .onSubmit {
                            Task {
                                dismissKeyboard()
                                _ = await viewModel.signIn()
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                isVisible.wrappedValue.toggle()
                focusedField = field
            }) {
                Image(systemName: isVisible.wrappedValue ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(LumaTheme.lavender.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .lumaInputBox(focused: focusedField == field)
    }
}

#Preview { LoginView() }
