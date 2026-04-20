import SwiftUI

struct MainView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var appUIState = AppUIState()
    @ObservedObject private var narrationPlayback = NarrationPlaybackCenter.shared

    @AppStorage("narration_panel_dx") private var narrationPanelDX: Double = 0
    @AppStorage("narration_panel_dy") private var narrationPanelDY: Double = 0

    @GestureState private var narrationDragTranslation: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottom) {
            LumaTheme.bg.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .create:
                    CreateStoryView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(appUIState)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)

            if appUIState.isTabBarVisible {
                LumaTabBar(selectedTab: $selectedTab)
            }

            if narrationPlayback.isPanelVisible {
                NarrationMiniPlayerView()
                    .padding(.horizontal, HomeDashboardMetrics.mainFloatingChromeHorizontalInset)
                    .padding(.bottom, narrationBottomPadding)
                    .offset(narrationDisplayedOffset)
                    .gesture(narrationDragGesture)
                    .accessibilityHint(String(localized: "Paneli sürükleyerek ekranda istediğiniz yere taşıyabilirsiniz."))
            }
        }
    }

    private var narrationBottomPadding: CGFloat {
        appUIState.isTabBarVisible ? 78 : 12
    }

    private var narrationDisplayedOffset: CGSize {
        let raw = CGSize(
            width: CGFloat(narrationPanelDX) + narrationDragTranslation.width,
            height: CGFloat(narrationPanelDY) + narrationDragTranslation.height
        )
        let c = clampNarrationOffset(dx: Double(raw.width), dy: Double(raw.height))
        return CGSize(width: c.0, height: c.1)
    }

    private var narrationDragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .updating($narrationDragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                var nextX = narrationPanelDX + Double(value.translation.width)
                var nextY = narrationPanelDY + Double(value.translation.height)
                (nextX, nextY) = clampNarrationOffset(dx: nextX, dy: nextY)
                narrationPanelDX = nextX
                narrationPanelDY = nextY
            }
    }

    /// Ekran içinde kal (tam ekran GeometryReader kullanmadan güvenli sınırlar).
    private func clampNarrationOffset(dx: Double, dy: Double) -> (Double, Double) {
        let maxAbsX: Double = 165
        let minY: Double = -420
        let maxY: Double = 72
        let x = min(max(dx, -maxAbsX), maxAbsX)
        let y = min(max(dy, minY), maxY)
        return (x, y)
    }
}

#Preview {
    MainView()
        .environmentObject(SubscriptionManager())
}
