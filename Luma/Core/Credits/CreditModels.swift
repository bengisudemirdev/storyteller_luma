import Foundation

enum CreditCost {
    static let story = 500
    static let narration = 3000
    static let fullAudioStory = 3500
}

struct CreditPackageConfig: Identifiable, Equatable {
    let id: String
    let revenueCatPackageIdentifier: String
    let title: String
    let subtitle: String
    let badge: String?
    let credits: Int
    let displayPrice: String
    let valueHint: String
    let ctaTitle: String

    static let all: [CreditPackageConfig] = [
        .init(
            id: "olia_credits_starter",
            revenueCatPackageIdentifier: "starter",
            title: "Starter",
            subtitle: "Başlangıç için ideal",
            badge: "Başlangıç için ideal",
            credits: 1000,
            displayPrice: "99,99 TL",
            valueHint: "2 masal",
            ctaTitle: "Starter Al"
        ),
        .init(
            id: "olia_credits_plus",
            revenueCatPackageIdentifier: "plus",
            title: "Plus",
            subtitle: "Günlük kullanım için dengeli",
            badge: "En Popüler",
            credits: 2500,
            displayPrice: "199,99 TL",
            valueHint: "5 masal",
            ctaTitle: "Plus Al"
        ),
        .init(
            id: "olia_credits_family",
            revenueCatPackageIdentifier: "family",
            title: "Family",
            subtitle: "Aile kullanımı için güçlü",
            badge: "Aile Paketi",
            credits: 7500,
            displayPrice: "399,99 TL",
            valueHint: "2 seslendirme + 3 masal",
            ctaTitle: "Family Al"
        ),
        .init(
            id: "olia_credits_mega",
            revenueCatPackageIdentifier: "mega",
            title: "Mega",
            subtitle: "Yoğun kullanımda en iyi değer",
            badge: "En İyi Değer",
            credits: 20000,
            displayPrice: "799,99 TL",
            valueHint: "5 tam sesli masal + 5 masal",
            ctaTitle: "Mega Al"
        )
    ]
}

struct CreditBalanceResponse: Decodable {
    let balance: Int
    let updatedAt: String?
}

