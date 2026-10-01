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
    /// RevenueCat / StoreKit fiyatı veya ürün yoksa yedek metin (örn. ₺179,99 / ay, ₺1.799,99 / yıl).
    let priceText: String
    let features: [String]

    static let monthlyFallbackPrice = "₺179,99 / ay"
    static let yearlyFallbackPrice = "₺1.799,99 / yıl"

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

    /// - Parameters:
    ///   - savingsPercent: Aylık plana göre yıllığın tasarruf yüzdesi (yalnızca gerçekten ucuzsa verilir).
    ///   - perMonthText: Yıllık fiyatın aylık karşılığı (mağazanın para birimiyle, örn. "₺149,99").
    static func yearlyPlan(priceText: String, savingsPercent: Int? = nil, perMonthText: String? = nil) -> PaywallPlanViewData {
        var benefitLines: [String] = []
        if let perMonthText {
            if let savingsPercent {
                benefitLines.append("Ayda yalnızca \(perMonthText) (aylık plana göre %\(savingsPercent) tasarruf)")
            } else {
                benefitLines.append("Ayda yalnızca \(perMonthText)")
            }
        }
        return PaywallPlanViewData(
            type: .yearly,
            title: "Yıllık Premium",
            badge: savingsPercent.map { "%\($0) tasarruf" } ?? "Yıllık",
            priceText: priceText,
            features: benefitLines + [
                // Yıllık avantajı (backend `planService` ile aynı): daha fazla masal ve çocuk profili; sesli hak aynı.
                "Ayda 45 kişiselleştirilmiş masal (aylık planda 30)",
                "Ayda 10 sesli masal hakkı",
                "4 çocuk profili (aylık planda 3)",
                "Masal arşivi",
                "Reklamsız deneyim"
            ]
        )
    }
}


/// Yıllık planın aylığa göre avantajını hesaplar.
enum PaywallPricing {
    /// Yıllık fiyatın aylık karşılığı, aylık plan fiyatından en az %5 ucuzsa tasarruf yüzdesini döndürür; değilse `nil`
    /// (avantaj yokken "tasarruf" iddiasında bulunulmaz).
    static func yearlySavingsPercent(monthly: Decimal, yearly: Decimal) -> Int? {
        guard monthly > 0, yearly > 0 else { return nil }
        let perMonth = yearly / 12
        let ratio = (Double(truncating: (perMonth / monthly) as NSDecimalNumber))
        let percent = Int(((1 - ratio) * 100).rounded())
        return percent >= 5 ? percent : nil
    }
}
