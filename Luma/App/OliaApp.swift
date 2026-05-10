import SwiftUI
import Supabase
import RevenueCat

@main
struct OliaApp: App {
    @StateObject private var authManager = AuthManager()
    @AppStorage("luma_has_completed_app_onboarding") private var hasCompletedAppOnboarding = false
    @AppStorage("luma_registration_requires_child_setup") private var registrationRequiresChildSetup = false
    /// İlk kurulumda marka splash → onboarding; tamamlanınca giriş veya ana ekran (oturum durumuna göre).
    @AppStorage("luma_has_seen_title_splash") private var hasSeenTitleSplash = false
    @State private var isPresentingPostRegistrationPaywall = false

    static let supabase = SupabaseClient(
        supabaseURL: AppConfig.supabaseURL,
        supabaseKey: AppConfig.supabaseAnonKey
    )

    init() {
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !authManager.isSessionChecked {
                    sessionLoadingView
                } else if !hasCompletedAppOnboarding {
                    if !hasSeenTitleSplash {
                        OnboardingTitleSplashView {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                hasSeenTitleSplash = true
                            }
                        }
                    } else {
                        OnboardingContainerView {
                            hasCompletedAppOnboarding = true
                        }
                    }
                } else if authManager.isAuthenticated {
                    ZStack {
                        if registrationRequiresChildSetup {
                            RegistrationChildSetupView {
                                registrationRequiresChildSetup = false
                            }
                        } else {
                            MainView()
                        }
                    }
                    .sheet(isPresented: $isPresentingPostRegistrationPaywall, onDismiss: {
                        UserDefaults.standard.set(false, forKey: LumaUserDefaultsKeys.showPostRegistrationPaywallOnce)
                    }) {
                        PaywallView(source: .manual)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                            .presentationCornerRadius(28)
                    }
                } else {
                    LoginView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lumaPresentPostRegistrationPaywall)) { _ in
                Task { @MainActor in
                    await handlePostRegistrationPaywallRequest()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: authManager.isSessionChecked)
            .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.25), value: registrationRequiresChildSetup)
            .animation(.easeInOut(duration: 0.35), value: hasCompletedAppOnboarding)
            .animation(.easeInOut(duration: 0.35), value: hasSeenTitleSplash)
            .task {
                if authManager.isAuthenticated {
                    await EntitlementStore.shared.refreshFromBackend()
                    await SubscriptionManager.shared.refreshPlanFromServer()
                    await CreditBalanceViewModel.shared.syncFromBackend()
                } else {
                    await CreditBalanceViewModel.shared.refreshBalance()
                }
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    Task {
                        await EntitlementStore.shared.refreshFromBackend()
                        await SubscriptionManager.shared.refreshPlanFromServer()
                        await CreditBalanceViewModel.shared.syncFromBackend()
                    }
                } else {
                    EntitlementStore.shared.clearForLogout()
                }
            }
        }
    }

    private var sessionLoadingView: some View {
        ZStack {
            LumaTheme.bg.ignoresSafeArea()
            ProgressView()
                .tint(LumaTheme.lavender)
                .scaleEffect(1.2)
        }
    }

    @MainActor
    private func handlePostRegistrationPaywallRequest() async {
        guard !isPresentingPostRegistrationPaywall else { return }
        await EntitlementStore.shared.refreshFromBackend()
        await SubscriptionManager.shared.refreshPlanFromServer()
        if EntitlementStore.shared.hasPremiumAccess {
            return
        }
        await CreditBalanceViewModel.shared.refreshBalance()
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard !isPresentingPostRegistrationPaywall else { return }
        isPresentingPostRegistrationPaywall = true
    }
}

#Preview("Title splash") {
    OnboardingTitleSplashView(onFinished: {})
}

#Preview("App Onboarding Flow") {
    OnboardingContainerView(onFinished: {})
}
