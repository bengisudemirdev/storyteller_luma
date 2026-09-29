import Foundation

enum PaywallPlanType: Hashable {
    case monthly
    case yearly
}

struct PaywallPlanViewData: Identifiable {
    var id: PaywallPlanType { type }
    let type: PaywallPlanType
    let title: String
    let badge: String?
    /// RevenueCat / StoreKit fiyatı veya ürün yoksa yedek metin (örn. ₺179,99 / ay).
    let priceText: String
    let features: [String]

    static let monthlyFallbackPrice = "₺179,99 / ay"
    static let yearlyFallbackPrice = "Yıllık fiyat App Store’dan yükleniyor"

    static func premiumPlan(priceText: String) -> PaywallPlanViewData {
        PaywallPlanViewData(
            type: .monthly,
            title: "Aylık Premium",
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

    static func yearlyPlan(priceText: String) -> PaywallPlanViewData {
        PaywallPlanViewData(
            type: .yearly,
            title: "Yıllık Premium",
            badge: "Yıllık",
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
}
