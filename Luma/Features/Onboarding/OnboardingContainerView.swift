import SwiftUI
import UIKit

/// Çok adımlı onboarding: özel gösterge, atla, yumuşak sayfa geçişleri.
struct OnboardingContainerView: View {
    let onFinished: () -> Void

    @State private var currentPage = 0
    @State private var showFairyDustBurst = false

    var body: some View {
        ZStack {
            OnboardingWarmBackground()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    OnboardingWelcomePage(onFairyBurst: {
                        showFairyDustBurst = true
                    })
                        .tag(0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    OnboardingValuePage(onContinue: { advanceTo(2) })
                        .tag(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    OnboardingStepsPage(onContinue: { advanceTo(3) })
                        .tag(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    OnboardingStoryTypesPage(onContinue: { advanceTo(4) })
                        .tag(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    OnboardingFinishPage(onFinish: onFinished)
                        .tag(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.45), value: currentPage)

                OnboardingPageIndicator(current: currentPage, total: OnboardingPageModel.pageCount)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
            }

            if showFairyDustBurst {
                OnboardingFairyDustOverlay {
                    showFairyDustBurst = false
                    advanceTo(1)
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .animation(.easeOut(duration: 0.28), value: showFairyDustBurst)
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(OnboardingPalette.templateTitleBrown)
                Text("Olia")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(OnboardingPalette.templateTitleBrown)
            }
            .padding(.leading, 20)

            Spacer(minLength: 0)

            Button("Atla") {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onFinished()
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(OnboardingPalette.muted.opacity(0.85))
            .padding(.trailing, 20)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func advanceTo(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.45)) {
            currentPage = index
        }
    }
}

#Preview("Onboarding") {
    OnboardingContainerView(onFinished: {})
}
