import Foundation

enum LumaUserDefaultsKeys {
    /// Kayıt (çocuk profili dahil) bittikten sonra ana ekranda bir kez paywall göster.
    static let showPostRegistrationPaywallOnce = "luma_show_post_registration_paywall_once"
}

extension Notification.Name {
    /// Çocuk profili kaydı tamamlandı; ana ekran hazır olduktan sonra paywall bottom sheet açılır.
    static let lumaPresentPostRegistrationPaywall = Notification.Name("lumaPresentPostRegistrationPaywall")
    /// Kayıtlı masallar listesi güncellenmeli (örn. yeni masal oluşturuldu).
    static let lumaSavedStoriesDidChange = Notification.Name("lumaSavedStoriesDidChange")
}
