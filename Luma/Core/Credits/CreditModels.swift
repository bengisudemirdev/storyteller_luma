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
            subtitle: "Başlangıç için ideal",
            badge: "Başlangıç için ideal",
            credits: 1000,
            displayPrice: "79,99 TL",
            valueHint: "2 masal",
            ctaTitle: "Starter Al"
        ),
        .init(
            id: "olia_credits_plus",
            title: "Plus",
            subtitle: "Günlük kullanım için dengeli",
            badge: "En Popüler",
            credits: 2500,
            displayPrice: "149,99 TL",
            valueHint: "5 masal",
            ctaTitle: "Plus Al"
        ),
        .init(
            id: "olia_credits_family",
            title: "Family",
            subtitle: "Aile kullanımı için güçlü",
            badge: "Avantajlı Paket",
            credits: 7500,
            displayPrice: "299,99 TL",
            valueHint: "2 seslendirme + 3 masal",
            ctaTitle: "Family Al"
        ),
        .init(
            id: "olia_credits_mega",
            title: "Mega",
            subtitle: "Yoğun kullanımda en iyi değer",
            badge: "En İyi Değer",
            credits: 20000,
            displayPrice: "599,99 TL",
            valueHint: "6 seslendirme + 4 masal",
            ctaTitle: "Mega Al"
        )
    ]
}

struct CreditBalanceResponse: Decodable {
    let balance: Int
    let updatedAt: String?
}

