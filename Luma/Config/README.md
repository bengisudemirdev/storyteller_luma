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

| `.env` değişkeni                 | Açıklama                    |
|----------------------------------|-----------------------------|
| `SUPABASE_URL`                   | Supabase proje URL          |
| `SUPABASE_ANON_KEY`              | Supabase **anon** (public)  |
| `BACKEND_BASE_URL`               | Express API kökü (örn. `https://luma.beysemi.com`) |
| `REVENUECAT_API_KEY`             | RevenueCat public SDK key   |
| `REVENUECAT_SANDBOX_API_KEY`     | Debug/test store için RevenueCat public SDK key |
| `REVENUECAT_USE_TEST_STORE`      | Debug build’de sandbox/test store key seçimi (`true`/`false`) |
| `REVENUECAT_OFFERING_KEY`        | Geriye uyumlu ortak offering id; yeni kurulumda boş bırakın |
| `REVENUECAT_SUBSCRIPTION_OFFERING_KEY` | Premium/Family abonelik paywall offering id; boşsa ortak key/current kullanılır |
| `REVENUECAT_CREDITS_OFFERING_KEY` | Kredi mağazası offering id; boşsa ortak key/current kullanılır |
| `TERMS_OF_SERVICE_URL`           | Paywall’daki Kullanım Şartları linki |
| `PRIVACY_POLICY_URL`             | Paywall’daki Gizlilik Politikası linki |
| `FEEDBACK_EMAIL`                 | Profil ekranındaki geri bildirimin gideceği adres (`mailto:`). Boşsa yedek `olia.destek@gmail.com` kullanılır — kendi adresinizi yazın. |
| `CLASSIC_TALE_COVERS_BASE_URL`   | İsteğe bağlı klasik masal kapak CDN kökü |

> Backend’deki `luma-backend/.env` ile **aynı dosya değil**. Orada service role vb. var; iOS’ta yalnızca **anon** ve public anahtarlar kullanılır.

## Kodda kullanım

- `AppConfig.supabaseURL`, `AppConfig.supabaseAnonKey`, `AppConfig.backendBaseURL`
- RevenueCat: `Secrets.revenueCatAPIKey` (yine `.env` → üretilen dosyadan)

`Secrets.generated.swift` **elle düzenlenmez**; `.gitignore` içindedir.
