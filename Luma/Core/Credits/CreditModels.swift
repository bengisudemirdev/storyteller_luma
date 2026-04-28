import Foundation

enum CreditCost {
    static let story = 500
    static let narration = 3000
    static let fullAudioStory = 3500
}

struct CreditPackageConfig: Identifiable, Equatable {
    let id: String
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
            title: "Starter",
            subtitle: "Baslangic icin ideal",
            badge: "Baslangic icin ideal",
            credits: 1000,
            displayPrice: "99,99 TL",
            valueHint: "2 masal",
            ctaTitle: "Starter Al"
        ),
        .init(
            id: "olia_credits_plus",
            title: "Plus",
            subtitle: "Gunluk kullanim icin dengeli",
            badge: "En populer",
            credits: 2500,
            displayPrice: "199,99 TL",
            valueHint: "5 masal",
            ctaTitle: "Plus Al"
        ),
        .init(
            id: "olia_credits_family",
            title: "Family",
            subtitle: "Aile kullanimi icin guclu",
            badge: "Aile favorisi",
            credits: 7500,
            displayPrice: "399,99 TL",
            valueHint: "2 seslendirme + 3 masal",
            ctaTitle: "Family Al"
        ),
        .init(
            id: "olia_credits_mega",
            title: "Mega",
            subtitle: "Yogun kullanimda en iyi deger",
            badge: "En iyi deger",
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

