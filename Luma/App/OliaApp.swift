import SwiftUI
import Supabase
import RevenueCat

@main
struct OliaApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @AppStorage("luma_has_completed_app_onboarding") private var hasCompletedAppOnboarding = false
    /// İlk kurulumda marka splash → onboarding; tamamlanınca giriş veya ana ekran (oturum durumuna göre).
    @AppStorage("luma_has_seen_title_splash") private var hasSeenTitleSplash = false

    static let supabase = SupabaseClient(
        supabaseURL: AppConfig.supabaseURL,
        supabaseKey: AppConfig.supabaseAnonKey
    )

    init() {
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
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
                    MainView()
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: authManager.isSessionChecked)
            .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.35), value: hasCompletedAppOnboarding)
            .animation(.easeInOut(duration: 0.35), value: hasSeenTitleSplash)
            .environmentObject(subscriptionManager)
            .task {
                await subscriptionManager.refreshPlanFromServer()
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
}

#Preview("Title splash") {
    OnboardingTitleSplashView(onFinished: {})
}

#Preview("App Onboarding Flow") {
    OnboardingContainerView(onFinished: {})
}
