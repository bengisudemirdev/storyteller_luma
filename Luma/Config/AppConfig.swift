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
        !Secrets.elevenLabsAPIKey.isEmpty && !Secrets.elevenLabsAgentId.isEmpty
    }
}
