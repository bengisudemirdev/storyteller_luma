import SwiftUI

/// Dostluk: sıcaklık, birliktelik, yumuşak duygusal güven.
struct FriendshipCoverTemplateView: View {
    let title: String
    var subtitle: String?
    var tag: String?
    var showsTextOverlay: Bool = true
    var titleOverlayExtraBottomInset: CGFloat = 0
    var cornerRadius: CGFloat
    var width: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "FDEBE5"),
                    Color(hex: "F5D5C8"),
                    Color(hex: "E8B8A8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // İki yumuşak “sarılma” halkası
            Circle()
                .fill(Color(hex: "FFD8CC").opacity(0.55))
                .frame(width: width * 0.55, height: width * 0.55)
                .offset(x: -width * 0.18, y: -width * 0.12)
                .blur(radius: 8)

            Circle()
                .fill(Color(hex: "FFE8B8").opacity(0.45))
                .frame(width: width * 0.5, height: width * 0.5)
                .offset(x: width * 0.2, y: -width * 0.08)
                .blur(radius: 10)

            Image(systemName: "heart.fill")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "F0A090").opacity(0.55), Color(hex: "E88880").opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -width * 0.18)

            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "D4946A").opacity(0.5))
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color(hex: "F0C878").opacity(0.65))
            }
            .offset(y: width * 0.06)

            ForEach(0..<6, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 2 + CGFloat(i % 3)))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .offset(
                        x: CGFloat([-55, 50, -40, 65, 0, 45][i]),
                        y: CGFloat([-95, -88, -70, -75, -110, -100][i])
                    )
            }

            if showsTextOverlay {
                VStack {
                    Spacer()
                    StoryCoverBottomScrim()
                        .frame(height: width * 0.55)
                }

                StoryCoverTitleOverlay(
                    title: title,
                    subtitle: subtitle,
                    tag: tag,
                    position: .bottom,
                    extraBottomInset: titleOverlayExtraBottomInset
                )
            }
        }
        .storyCoverFrame(width: width, cornerRadius: cornerRadius)
    }
}
