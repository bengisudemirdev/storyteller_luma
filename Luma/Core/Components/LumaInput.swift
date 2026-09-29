import SwiftUI

/// Uygulamadaki tüm metin girişleri için ortak ölçüler ve stil.
/// Önceden her ekran kutuyu kendi köşe yarıçapı/dolgu/arka planıyla çiziyordu (11–16 pt, beyaz/krem/yarı saydam);
/// yer tutucu ve yazı rengi de belirtilmediğinde koyu modda beyaz kutuda görünmez oluyordu.
enum LumaInput {
    static let cornerRadius: CGFloat = 14
    static let minHeight: CGFloat = 52
    static let multilineMinHeight: CGFloat = 120
    static let horizontalPadding: CGFloat = 14
}

/// Okunaklı yer tutucu (koyu/açık temadan bağımsız sabit renk).
func lumaPrompt(_ text: String) -> Text {
    Text(text).foregroundStyle(HomeDashboardPalette.muted.opacity(0.75))
}

extension View {
    /// Metin rengi, yazı tipi ve imleç rengi.
    func lumaInputText(size: CGFloat = 16) -> some View {
        self
            .font(.system(size: size, weight: .medium, design: .rounded))
            .foregroundStyle(HomeDashboardPalette.ink)
            .tint(HomeDashboardPalette.accentOrange)
    }

    /// Ortak kutu: aynı yükseklik, köşe, dolgu ve kenarlık. `focused` iken kenarlık vurgulanır.
    func lumaInputBox(focused: Bool = false, multiline: Bool = false) -> some View {
        self
            .padding(.horizontal, LumaInput.horizontalPadding)
            .padding(.vertical, multiline ? 14 : 0)
            .frame(
                maxWidth: .infinity,
                minHeight: multiline ? LumaInput.multilineMinHeight : LumaInput.minHeight,
                alignment: multiline ? .topLeading : .leading
            )
            .background(
                RoundedRectangle(cornerRadius: LumaInput.cornerRadius, style: .continuous)
                    .fill(HomeDashboardPalette.cardSurface)
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LumaInput.cornerRadius, style: .continuous)
                    .stroke(
                        HomeDashboardPalette.accentOrange.opacity(focused ? 0.55 : 0.18),
                        lineWidth: focused ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
    }
}
