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
            credits: 1500,
            displayPrice: "149,99 TL",
            valueHint: "3 masal",
            ctaTitle: "Starter Al"
        ),
        .init(
            id: "olia_credits_plus",
            title: "Plus",
            subtitle: "Gunluk kullanim icin dengeli",
            badge: "En populer",
            credits: 5000,
            displayPrice: "449,99 TL",
            valueHint: "1 tam sesli masal + 3 masal",
            ctaTitle: "Plus Al"
        ),
        .init(
            id: "olia_credits_family",
            title: "Family",
            subtitle: "Aile kullanimi icin guclu",
            badge: "Aile favorisi",
            credits: 12000,
            displayPrice: "949,99 TL",
            valueHint: "3 tam sesli masal + 1 masal",
            ctaTitle: "Family Al"
        ),
        .init(
            id: "olia_credits_mega",
            title: "Mega",
            subtitle: "Yogun kullanimda en iyi deger",
            badge: "En iyi deger",
            credits: 30000,
            displayPrice: "2.199,99 TL",
            valueHint: "8 tam sesli masal + 2 masal",
            ctaTitle: "Mega Al"
        )
    ]
}

struct CreditBalanceResponse: Decodable {
    let balance: Int
    let updatedAt: String?
}

