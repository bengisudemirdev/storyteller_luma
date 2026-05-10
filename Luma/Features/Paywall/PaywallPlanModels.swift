import Foundation

enum PaywallPlanType: Hashable {
    case premium
    case family
}

struct PaywallPlanViewData: Identifiable {
    var id: PaywallPlanType { type }
    let type: PaywallPlanType
    let title: String
    let badge: String?
    /// RevenueCat / StoreKit fiyatı veya ürün yoksa yedek metin (örn. ₺179,99 / ay).
    let priceText: String
    let features: [String]

    static let premiumFallbackPrice = "₺179,99 / ay"
    static let familyFallbackPrice = "₺349,99 / ay"

    static func premiumPlan(priceText: String) -> PaywallPlanViewData {
        PaywallPlanViewData(
            type: .premium,
            title: "Premium",
            badge: "En Popüler",
            priceText: priceText,
            features: [
                "Ayda 30 kişiselleştirilmiş masal",
                "Ayda 10 sesli masal hakkı",
                "3 çocuk profili",
                "Masal arşivi",
                "Reklamsız deneyim"
            ]
        )
    }

    static func familyPlan(priceText: String) -> PaywallPlanViewData {
        PaywallPlanViewData(
            type: .family,
            title: "Family",
            badge: "Aileler için",
            priceText: priceText,
            features: [
                "Ayda 100 kişiselleştirilmiş masal",
                "Ayda 30 sesli masal hakkı",
                "5 çocuk profili",
                "Öncelikli üretim",
                "Reklamsız deneyim"
            ]
        )
    }
}
