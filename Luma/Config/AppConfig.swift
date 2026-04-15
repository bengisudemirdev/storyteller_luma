//
//  AppConfig.swift
//  Luma
//
//  Gizli değerler Luma/Config/.env → derlemede Secrets.generated.swift (Scripts).
//

import Foundation

enum AppConfig {

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

    /// ElevenLabs Convai agent + API key tanımlıysa masal seslendirmesi bu sesi kullanır.
    static var isElevenLabsNarrationConfigured: Bool {
        let apiKey = Secrets.elevenLabsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let agentId = Secrets.elevenLabsAgentId.trimmingCharacters(in: .whitespacesAndNewlines)
        let voiceId = Secrets.elevenLabsVoiceId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { return false }
        if apiKey.contains("YOUR_") { return false }
        if !voiceId.isEmpty, !voiceId.contains("YOUR_") { return true }
        guard !agentId.isEmpty else { return false }
        if agentId.contains("YOUR_") { return false }
        return true
    }

    /// Agent'tan bağımsız, doğrudan kullanılacak voice id (opsiyonel).
    static var elevenLabsPreferredVoiceId: String? {
        let value = Secrets.elevenLabsVoiceId.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value.contains("YOUR_") {
            return nil
        }
        return value
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
