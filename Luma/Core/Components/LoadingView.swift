import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LumaTheme.bg.ignoresSafeArea()
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(LumaTheme.lavender.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 0.5)
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(LumaTheme.lavender)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) { isAnimating = true }
                }
                VStack(spacing: 10) {
                    Text("Masalın Hazırlanıyor...")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(LumaTheme.text)
                    Text("Peri tozları sayfalara serpiliyor ✨")
                        .font(.subheadline)
                        .foregroundColor(LumaTheme.secondaryText)
                }
            }
        }
    }
}

#Preview { LoadingView() }
