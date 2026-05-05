import SwiftUI
import Supabase

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var shouldShowChildSetup = false
    @AppStorage("luma_registration_requires_child_setup") private var registrationRequiresChildSetup = false
    @Environment(\.dismiss) private var dismiss

    private var canProceedStep1: Bool {
        let mail = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !viewModel.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && mail.contains("@") && mail.contains(".")
            && viewModel.password.count >= 6
            && viewModel.password == viewModel.confirmPassword
    }

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(HomeDashboardPalette.muted)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Color.white.opacity(0.9)))
                        }
                        .buttonStyle(.plain)
                    }

                    registrationStepChip(step: 1, title: "Ebeveyn bilgileri")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hesap oluştur")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(HomeDashboardPalette.ink)
                        Text(AppBrand.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                        Text("Sonraki adımda bir çocuk profili eklemen gerekir. Bu adım tamamlanmadan kayıt bitmez ve uygulamaya geçemezsin.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.22))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.2), lineWidth: 1)
                    )

                    VStack(spacing: 12) {
                        registrationLabeledField(
                            title: "Ad Soyad",
                            icon: "person.fill",
                            content: {
                                TextField("Adınız ve soyadınız", text: $viewModel.fullName)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(HomeDashboardPalette.ink)
                                    .textInputAutocapitalization(.words)
                            }
                        )

                        registrationLabeledField(
                            title: "E-posta",
                            icon: "envelope.fill",
                            content: {
                                TextField("ornek@eposta.com", text: $viewModel.email)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(HomeDashboardPalette.ink)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                        )

                        registrationSecureField(
                            title: "Şifre",
                            text: $viewModel.password,
                            isVisible: $isPasswordVisible
                        )

                        registrationSecureField(
                            title: "Şifre tekrar",
                            text: $viewModel.confirmPassword,
                            isVisible: $isConfirmPasswordVisible
                        )

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.red.opacity(0.08))
                                )
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .fill(HomeDashboardPalette.cardSurface)
                            .shadow(color: HomeDashboardPalette.cardShadow, radius: 14, x: 0, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.1), lineWidth: 1)
                    )

                    Button {
                        Task {
                            let didSignUp = await viewModel.signUp()
                            if didSignUp {
                                shouldShowChildSetup = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Devam et")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            LumaTheme.lavender,
                                            HomeDashboardPalette.nightMid.opacity(0.92)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: LumaTheme.lavender.opacity(0.35), radius: 14, x: 0, y: 7)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading || !canProceedStep1)
                    .opacity(viewModel.isLoading || canProceedStep1 ? 1 : 0.45)

                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Text("Zaten hesabın var mı?")
                                .foregroundStyle(HomeDashboardPalette.muted)
                            Text("Giriş yap")
                                .fontWeight(.bold)
                                .foregroundStyle(LumaTheme.lavender)
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                .padding(.top, 12)
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

    private func registrationStepChip(step: Int, title: String) -> some View {
        HStack(spacing: 8) {
            Text("\(step)/2")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(LumaTheme.lavender)
                )
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .tracking(0.6)
        }
    }

    private func registrationLabeledField<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(HomeDashboardPalette.creamDeep.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(HomeDashboardPalette.accentOrange.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private func registrationSecureField(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "lock.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
            HStack(spacing: 10) {
                Group {
                    if isVisible.wrappedValue {
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HomeDashboardPalette.creamDeep.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
