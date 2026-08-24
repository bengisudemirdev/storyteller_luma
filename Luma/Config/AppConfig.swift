//
//  AppConfig.swift
//  Luma
//
//  Gizli değerler Luma/Config/.env → derlemede Secrets.generated.swift (Scripts).
//

import Foundation

enum AppConfig {
    private static var shouldUseRevenueCatTestStore: Bool {
        let raw = Secrets.revenueCatUseTestStore.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return raw == "1" || raw == "true" || raw == "yes"
    }

    static var revenueCatAPIKey: String {
        #if DEBUG
        if shouldUseRevenueCatTestStore {
            let sandboxKey = Secrets.revenueCatSandboxAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !sandboxKey.isEmpty {
                return sandboxKey
            }
        }
        #endif
        return Secrets.revenueCatAPIKey
    }

    /// RevenueCat Offering identifier; boşsa SDK `current` offering kullanılır.
    static var revenueCatOfferingKey: String? {
        let key = Secrets.revenueCatOfferingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    /// Subscription paywall offering identifier. Falls back to the legacy common offering key, then RevenueCat current.
    static var revenueCatSubscriptionOfferingKey: String? {
        let key = Secrets.revenueCatSubscriptionOfferingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty { return key }
        return revenueCatOfferingKey
    }

    /// Credit store offering identifier. Falls back to the legacy common offering key, then RevenueCat current.
    static var revenueCatCreditsOfferingKey: String? {
        let key = Secrets.revenueCatCreditsOfferingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty { return key }
        return revenueCatOfferingKey
    }

    static var termsOfServiceURL: URL? {
        let raw = Secrets.termsOfServiceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let url = URL(string: raw) else { return nil }
        return url
    }

    static var privacyPolicyURL: URL? {
        let raw = Secrets.privacyPolicyURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let url = URL(string: raw) else { return nil }
        return url
    }

    static var isRevenueCatTestStoreMode: Bool {
        revenueCatAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("test_")
    }

    /// Log / destek için; tam RevenueCat anahtarı asla yazdırılmamalı.
    static var revenueCatAPIKeyRedactedPrefix: String {
        let raw = revenueCatAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "(empty)" }
        if raw.hasPrefix("appl_") { return "appl_***" }
        if raw.hasPrefix("test_") { return "test_***" }
        let n = min(8, raw.count)
        return String(raw.prefix(n)) + "***"
    }

    static var supabaseURL: URL {
        let urlString = Secrets.supabaseURL
        guard !urlString.isEmpty,
              urlString != "https://YOUR_PROJECT.supabase.co",
              let url = URL(string: urlString) else {
            fatalError("Luma/Config/.env içinde SUPABASE_URL tanımlayın (.env.example şablon). Derlemeden önce: cp Luma/Config/.env.example Luma/Config/.env")
        }
        return url
    }

    static var supabaseAnonKey: String {
        let key = Secrets.supabaseAnonKey
        guard !key.isEmpty, key != "YOUR_SUPABASE_ANON_KEY" else {
            fatalError("Luma/Config/.env içinde SUPABASE_ANON_KEY tanımlayın.")
        }
        return key
    }

    static var backendBaseURL: URL {
        let raw = Secrets.backendBaseURL
        guard !raw.isEmpty,
              let url = URL(string: raw) else {
            fatalError("Luma/Config/.env içinde BACKEND_BASE_URL tanımlayın.")
        }
        return url
    }

    /// Profil → Geri bildirim `mailto:` hedefi. `Luma/Config/.env` içinde `FEEDBACK_EMAIL` ile ayarlayın.
    static var feedbackRecipientEmail: String {
        let trimmed = Secrets.feedbackEmail.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed.contains("@") {
            return trimmed
        }
        return "olia.destek@gmail.com"
    }

    /// Klasik masal kapağı (`classic-tales/{taleId}/cover.png`). Önce `CLASSIC_TALE_COVERS_BASE_URL`; yoksa Supabase public object URL.
    /// Görseller: `luma-backend` içinde `npm run seed:classic-covers` (bucket herkese açık okunabilir olmalı).
    static func classicTaleCoverImageURL(taleId: String) -> URL? {
        let id = taleId.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) ?? taleId

        let customBase = Secrets.classicTaleCoversBaseURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !customBase.isEmpty {
            let trimmed = customBase.hasSuffix("/") ? String(customBase.dropLast()) : customBase
            return URL(string: "\(trimmed)/\(id)/cover.png")
        }

        let supabase = Secrets.supabaseURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !supabase.isEmpty,
              !supabase.contains("YOUR_PROJECT") else { return nil }

        // Backend `SUPABASE_STORAGE_BUCKET_STORIES` ile aynı; farklı bucket için `CLASSIC_TALE_COVERS_BASE_URL` kullan.
        let bucket = "luma-stories-assets"

        let root = supabase.hasSuffix("/") ? String(supabase.dropLast()) : supabase
        let path = "/storage/v1/object/public/\(bucket)/classic-tales/\(id)/cover.png"
        return URL(string: root + path)
    }
}
