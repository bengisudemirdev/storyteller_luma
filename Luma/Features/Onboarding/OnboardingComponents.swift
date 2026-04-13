import SwiftUI
import AVFoundation

// MARK: - Onboarding palette (beige, şeftali, lavanta, tozlu mavi)

enum OnboardingPalette {
    static let parchment = Color(hex: "FAF6EF")
    static let parchmentDeep = Color(hex: "F2E8DC")
    static let peachMist = Color(hex: "F4D4C8")
    static let lavenderMist = Color(hex: "DDD4E8")
    static let dustyBlue = Color(hex: "A8BED6")
    static let goldSoft = Color(hex: "E8C9A0")
    static let ink = Color(hex: "2C2A32")
    static let muted = Color(hex: "6B6560")
    static let accentPeach = Color(hex: "E8956A")
    /// Şablon onboarding: krem ekran, kahverengi CTA
    static let templateCream = Color(hex: "F5F0E6")
    static let templateCreamDeep = Color(hex: "F2EBE3")
    static let templateTaupeBottom = Color(hex: "D9CEC3")
    static let templateTitleBrown = Color(hex: "3A2F28")
    static let templateCTABrown = Color(hex: "8B6D58")
    /// Splash ve karşılama başlıkları (mürdüm-kahve)
    static let titlePlum = Color(hex: "5C4B51")
    /// İkincil metin (splash alt başlığı ile uyumlu)
    static let subtitleGray = Color(hex: "8E8E8E")
}

// MARK: - Arka plan

struct OnboardingWarmBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    OnboardingPalette.templateCream,
                    OnboardingPalette.templateCreamDeep,
                    OnboardingPalette.templateTaupeBottom.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LoopingBackgroundVideoView(
                    resourceName: "onboarding_bg_loop",
                    resourceExtension: "mp4"
                )
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.62)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(0.55), location: 0.22),
                            .init(color: .white, location: 0.45),
                            .init(color: .white, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(0.28)
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

private struct LoopingBackgroundVideoView: UIViewRepresentable {
    let resourceName: String
    let resourceExtension: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        guard
            let path = Bundle.main.path(forResource: resourceName, ofType: resourceExtension)
        else {
            return view
        }

        let player = AVPlayer(url: URL(fileURLWithPath: path))
        player.isMuted = true
        player.actionAtItemEnd = .none

        context.coordinator.player = player
        context.coordinator.endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        uiView.playerLayer.player = nil
        if let observer = coordinator.endObserver {
            NotificationCenter.default.removeObserver(observer)
            coordinator.endObserver = nil
        }
        coordinator.player = nil
    }

    final class Coordinator {
        var player: AVPlayer?
        var endObserver: NSObjectProtocol?
    }
}

private final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - CTA

struct OnboardingCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    OnboardingPalette.templateCTABrown.opacity(0.98),
                                    OnboardingPalette.templateTitleBrown.opacity(0.92)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.38), lineWidth: 1.5)
                        )
                        .shadow(color: OnboardingPalette.templateCTABrown.opacity(0.45), radius: 18, x: 0, y: 10)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}

/// Hafif basınç animasyonu (mikro etkileşim).
struct OnboardingScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Typography

enum OnboardingTypography {
    static let title: CGFloat = 30
    static let sectionTitle: CGFloat = 26
    static let body: CGFloat = 15
    static let bodySmall: CGFloat = 14
    static let cardTitle: CGFloat = 16
}

// MARK: - Sayfa göstergesi

struct OnboardingPageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(
                        index == current
                            ? OnboardingPalette.templateCTABrown
                            : OnboardingPalette.muted.opacity(0.28)
                    )
                    .frame(width: 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sayfa \(current + 1) / \(total)")
    }
}

// MARK: - Ortak sayfa iskeleti

/// Üstte kaydırılabilir içerik (butonların üstünde kalan alanı doldurur), altta sabit CTA.
struct OnboardingPageLayout<ScrollContent: View, Footer: View>: View {
    @ViewBuilder var scrollContent: () -> ScrollContent
    @ViewBuilder var footer: () -> Footer

    /// CTA + alt padding (yaklaşık; sabit hizalama için).
    private var bottomReservedHeight: CGFloat { 104 }

    var body: some View {
        GeometryReader { proxy in
            let scrollMin = max(0, proxy.size.height - bottomReservedHeight)

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        scrollContent()
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: scrollMin, alignment: .top)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer()
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
