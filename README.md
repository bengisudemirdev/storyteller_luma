# Olia

Olia, ebeveynlerin çocukları için yaşa uygun, güvenli ve kişiselleştirilmiş masallar oluşturmasını sağlayan iOS uygulamasıdır. Uygulama çocuk profili, ilgi alanları, tema seçimi ve hassasiyetleri kullanarak masal üretir; oluşturulan masallar okunabilir, kaydedilebilir ve sesli hale getirilebilir.

Bu repo, SwiftUI ile geliştirilmiş iOS uygulamasını ve API entegrasyon katmanlarını içerir. Ürün odağı yalnızca "AI ile hikaye üretmek" değil; çocuk güvenliği, ebeveyn kontrolü, sesli deneyim ve ölçeklenebilir abonelik mimarisini bir araya getiren uçtan uca bir mobil ürün deneyimidir.

## Öne Çıkanlar

- **Kişiselleştirilmiş masal üretimi:** Çocuk profili, tema, ilgi alanları ve ek bağlam ile her kullanıcıya özel masallar.
- **Çocuk güvenliği odaklı RAG/policy katmanı:** Yaş grubu, ton, riskli içerik yönlendirme ve güvenli son kurallarıyla kontrollü üretim akışı.
- **Sesli masal deneyimi:** Kayıtlı masallar ve klasik masallar için backend destekli seslendirme akışı.
- **Klasik masal kütüphanesi:** API destekli klasik masal listesi, detay ekranı ve ses önbellekleme.
- **Modern SwiftUI arayüz:** Onboarding, dashboard, masal oluşturma, okuma deneyimi, profil ve özel tab bar.
- **Supabase authentication:** Oturum yönetimi, kullanıcı senkronizasyonu ve güvenli API istekleri.
- **RevenueCat mimarisi:** Premium/family abonelik, entitlement ve satın alma senkronizasyonu için hazır servis katmanı.
- **Kontrollü erişim modu:** Geliştirme ve test süreçlerinde ödeme akışına takılmadan temel deneyimi doğrulama.

## Ürün Akışı

1. Kullanıcı onboarding'i tamamlar ve giriş/kayıt olur.
2. Çocuk profili oluşturur veya hızlı masal üretim formunu kullanır.
3. Tema, ilgi alanı ve isteğe bağlı ek bağlam seçilir.
4. Backend üzerinden kişiselleştirilmiş masal üretilir.
5. Masal okuyucu ekranında içerik sayfalara bölünür, kaydedilir ve seslendirilebilir.
6. Ana ekranda son masallar, klasik masallar ve hızlı aksiyonlar gösterilir.

## Teknik Mimari

```text
SwiftUI iOS App
  |
  |-- Features
  |   |-- Auth, Onboarding, Home, CreateStory, Reader, Profile, Paywall
  |
  |-- Services
  |   |-- APIClient + endpoint servisleri
  |   |-- AuthManager + Supabase session yönetimi
  |   |-- RevenueCat billing ve entitlement servisleri
  |
  |-- Core
  |   |-- EntitlementStore
  |   |-- SubscriptionManager
  |   |-- Theme, components, error mapping
  |
  |-- Backend API
      |-- Story generation
      |-- Story narration
      |-- Classic tales
      |-- Credits / subscriptions / entitlements
```

### iOS

- **SwiftUI** ile deklaratif ekran mimarisi.
- **MVVM yaklaşımı** ile ekran state'i view model katmanında tutulur.
- **Async/await** ile Supabase ve backend API çağrıları yönetilir.
- **Centralized API layer** sayesinde endpoint, auth header, retry ve decoding davranışları tek yerde toplanır.
- **EntitlementStore + SubscriptionManager** ile ödeme/hak kontrolleri UI'dan ayrılır.

### Backend Entegrasyonu

Uygulama backend'e `BACKEND_BASE_URL` üzerinden bağlanır. Mobil tarafta aşağıdaki servisler backend kontratlarını soyutlar:

- `StoryAPIService`: masal üretimi, listeleme, silme ve seslendirme.
- `ClassicTalesAPIService`: klasik masal listesi, detay ve ses üretimi.
- `ChildrenAPIService`: çocuk profili CRUD akışı.
- `EntitlementAPIService`: abonelik ve kullanım hakları.
- `CreditAPIService`: kredi bakiyesi, IAP sync ve işlem geçmişi.
- `AuthAPIService`: backend kullanıcı senkronizasyonu.

### Güvenli Üretim Katmanı

`Luma/AI` altında yer alan policy ve RAG helper yapıları, çocuk içerik güvenliğini ürünün merkezine alır:

- Yaş grubuna göre dil ve gerilim seviyesi.
- Riskli terimlerde hard block / soft redirect yaklaşımı.
- Korku ve hassasiyetleri güvenli biçimde ele alma.
- Hikayeyi açıklama değil, doğrudan çocuk dostu çıktı olarak döndürme.

## Geliştirme Erişim Modu

Geliştirme ve test süreçlerinde ödeme akışına takılmadan temel ürün deneyimini doğrulamak için kontrollü erişim modu bulunur.

Bu mod şu dosyadan yönetilir:

```swift
// Luma/Config/PortfolioAccessMode.swift
#if DEBUG
static let isEnabled = true
#else
static let isEnabled = false
#endif
```

Erişim modu açıkken:

- RevenueCat SDK başlatılmaz.
- Kullanıcı premium erişimli kabul edilir.
- Masal oluşturma ve seslendirme hak kontrolleri istemci tarafında açık döner.
- Paywall ve satın alma CTA'ları görünmez.
- Profilde abonelik yerine test erişimi mesajı gösterilir.

Gerçek ödeme akışını Debug ortamında da test etmek için:

```swift
static let isEnabled = false
```

> Not: Bu mod istemci tarafındaki ödeme duvarını kaldırır. Release build’lerde otomatik olarak kapalıdır; yine de backend de aynı kurguya alınmalıdır, aksi halde backend kota/ödeme nedeniyle bazı üretim veya seslendirme isteklerini reddedebilir.

## Kurulum

### Gereksinimler

- Xcode 16 veya üzeri
- iOS Simulator veya gerçek iOS cihaz
- Swift Package Manager
- Supabase proje bilgileri
- Backend API URL'i
- RevenueCat anahtarı, gerçek ödeme akışı açılacaksa

### 1. Repo'yu aç

```bash
open Luma.xcodeproj
```

### 2. iOS environment dosyasını hazırla

```bash
cp Luma/Config/.env.example Luma/Config/.env
```

Ardından `Luma/Config/.env` içindeki değerleri doldur. Bu dosya gizli anahtar içerdiği için commit edilmemelidir:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
BACKEND_BASE_URL=
REVENUECAT_API_KEY=
REVENUECAT_SANDBOX_API_KEY=
REVENUECAT_USE_TEST_STORE=false
REVENUECAT_OFFERING_KEY=
REVENUECAT_SUBSCRIPTION_OFFERING_KEY=
REVENUECAT_CREDITS_OFFERING_KEY=
TERMS_OF_SERVICE_URL=
PRIVACY_POLICY_URL=
FEEDBACK_EMAIL=
ELEVENLABS_API_KEY=
ELEVENLABS_AGENT_ID=
ELEVENLABS_VOICE_ID=
CLASSIC_TALE_COVERS_BASE_URL=
```

Build sırasında `scripts/generate_ios_secrets.py` çalışır ve `Luma/Config/Secrets.generated.swift` üretilir.

### 3. Build al

```bash
xcodebuild -project Luma.xcodeproj \
  -scheme Luma \
  -destination generic/platform=iOS \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```



## Proje Yapısı

```text
Luma/
  AI/                  # Çocuk güvenliği ve RAG/policy yardımcıları
  App/                 # App entry, onboarding splash
  Config/              # AppConfig, secrets, controlled access mode
  Core/                # Ortak state, theme, entitlement, subscription
  Features/            # Auth, Home, CreateStory, Reader, Profile, Paywall
  Models/              # Child ve Story modelleri
  Services/            # API, billing, auth ve story servisleri
  Views/               # Paylaşılan view parçaları

LumaTests/             # Unit test hedefi
LumaUITests/           # UI test hedefi
scripts/               # Secret generation ve yardımcı scriptler
luma-backend/          # Backend yardımcı scriptleri / entegrasyon materyalleri
```

## Neden Dikkate Değer?

Olia, birkaç güçlü mühendislik kararını aynı üründe birleştirir:

- AI tabanlı bir fikri yalnızca prompt seviyesinde bırakmayıp, mobil ürün deneyimine dönüştürür.
- Çocuk içeriği gibi hassas bir domain için policy-first tasarım kullanır.
- Satın alma, entitlement, backend sync ve kontrollü erişim gibi gerçek ürün operasyonu problemlerini ele alır.
- SwiftUI ekranlarını API, auth ve state yönetimiyle uçtan uca bağlar.
- Hata toleransı, fallback klasik masallar, ses önbellekleme ve retry gibi ürün kalitesini artıran detaylar içerir.

## Durum

Ödeme akışı mimari olarak korunmuştur. Production'a çıkış öncesi kontrollü erişim modunun kapatılması, RevenueCat ürünlerinin App Store Connect ile doğrulanması ve uçtan uca satın alma testlerinin tamamlanması gerekir.

## Release Öncesi Checklist

- `Luma/Config/.env` gerçek değerlerle dolduruldu: Supabase, backend, RevenueCat, Terms, Privacy ve feedback mail.
- `Luma/Config/.env` git takibinden çıkarıldı; dosya `.gitignore` içinde kalmalı ve commit edilmemeli.
- `Luma/Config/Secrets.generated.swift` git takibinde değil; build sırasında yerelde üretiliyor.
- `PortfolioAccessMode.isEnabled` Release build'de `false`; gerçek entitlement ve kredi kontrolleri aktif.
- RevenueCat subscription offering id (`REVENUECAT_SUBSCRIPTION_OFFERING_KEY`) Premium/Family paketlerinin olduğu offering ile aynı.
- RevenueCat credits offering id (`REVENUECAT_CREDITS_OFFERING_KEY`) kredi paketlerinin olduğu offering ile aynı.
- RevenueCat subscription ve credit package id'leri App Store Connect ürünleriyle eşleşiyor.
- Sandbox/Test Store ile satın alma, restore purchases ve backend IAP sync akışı test edildi.
- Terms of Service ve Privacy Policy linkleri paywall'dan açılıyor.
- Login, tab navigasyon, hikaye oluşturma ve profil çıkış akışları gerçek test hesabıyla geçti.
- Release build `CODE_SIGNING_ALLOWED=NO` ile lokal olarak başarıyla tamamlandı.
