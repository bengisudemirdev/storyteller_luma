import SwiftUI

/// Olia masal kapakları için seçilebilir şablon kimlikleri.
enum StoryCoverTemplateType: String, CaseIterable, Identifiable, Codable, Sendable {
    case sleep
    case forest
    case castle
    case friendship
    case space
    case ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep: return "Uyku"
        case .forest: return "Orman"
        case .castle: return "Şato"
        case .friendship: return "Dostluk"
        case .space: return "Uzay"
        case .ocean: return "Deniz"
        }
    }
}

/// Kapak bileşenleri için ortak ölçüler (dikey kart oranı).
enum StoryCoverMetrics {
    static let cornerRadius: CGFloat = 22
    static let defaultWidth: CGFloat = 200
    /// Dikey kart: yükseklik = genişlik × bu oran (4:3 portre).
    static let heightMultiplier: CGFloat = 4 / 3

    static func size(width: CGFloat) -> CGSize {
        CGSize(width: width, height: width * heightMultiplier)
    }
}

extension View {
    /// Dikey kapak çerçevesi, sürekli köşe ve yumuşak gölge.
    func storyCoverFrame(width: CGFloat, cornerRadius: CGFloat) -> some View {
        frame(width: width, height: width * StoryCoverMetrics.heightMultiplier)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.11), radius: 14, x: 0, y: 7)
    }
}
