# Config & gizli anahtarlar (iOS)

## `.env` (commit edilmez)

1. Şablonu kopyala:  
   `cp Luma/Config/.env.example Luma/Config/.env`
2. `Luma/Config/.env` içindeki değerleri doldur.
3. Xcode’da **Build** — “Generate Secrets from .env” aşaması `Secrets.generated.swift` dosyasını üretir.

Manuel üretmek için (terminal):

```bash
python3 scripts/generate_ios_secrets.py
```

## Anahtarlar

| `.env` değişkeni        | Açıklama                    |
|-------------------------|-----------------------------|
| `SUPABASE_URL`          | Supabase proje URL          |
| `SUPABASE_ANON_KEY`     | Supabase **anon** (public)  |
| `BACKEND_BASE_URL`      | Express API kökü (örn. `https://luma.beysemi.com`) |
| `REVENUECAT_API_KEY`    | RevenueCat public SDK key   |
| `ELEVENLABS_API_KEY`    | ElevenLabs API key (masal seslendirme; boşsa iOS `AVSpeech` kullanılır) |
| `ELEVENLABS_AGENT_ID`   | Convai agent ID (dashboard’daki agent) |
| `FEEDBACK_EMAIL`        | Profil ekranındaki geri bildirimin gideceği adres (`mailto:`). Boşsa yedek `olia.destek@gmail.com` kullanılır — kendi adresinizi yazın. |

> Backend’deki `luma-backend/.env` ile **aynı dosya değil**. Orada service role vb. var; iOS’ta yalnızca **anon** ve public anahtarlar kullanılır.

## Kodda kullanım

- `AppConfig.supabaseURL`, `AppConfig.supabaseAnonKey`, `AppConfig.backendBaseURL`
- RevenueCat: `Secrets.revenueCatAPIKey` (yine `.env` → üretilen dosyadan)

`Secrets.generated.swift` **elle düzenlenmez**; `.gitignore` içindedir.
