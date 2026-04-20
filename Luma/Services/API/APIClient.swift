import Foundation

struct APIErrorPayload: Decodable {
    let code: String
    let message: String
}

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: APIErrorPayload?
}

enum APIClientError: LocalizedError {
    case invalidURL
    case unauthorized
    case server(code: String, message: String)
    case decodingFailed
    case invalidResponse
    case emptyData
    /// Sunucuya ulaşılamıyor (ATS, yanlış URL, kapalı backend, DNS vb.).
    case networkFailure(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz API URL."
        case .unauthorized:
            return "Yetkilendirme başarısız. Lütfen tekrar giriş yapın."
        case .server(let code, let message):
            if let mapped = Self.turkishMessageForServerError(code: code, message: message) {
                return mapped
            }
            return "Sunucu isteği işleyemedi. Lütfen tekrar deneyin."
        case .decodingFailed:
            return "Sunucu yanıtı işlenemedi."
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı alındı."
        case .emptyData:
            return "Sunucudan boş yanıt alındı."
        case .networkFailure(let message):
            return message
        }
    }

    /// Sunucunun `code` + `message` alanlarına göre kullanıcıya gösterilecek Türkçe metin; bilinmiyorsa `nil`.
    fileprivate static func turkishMessageForServerError(code: String, message: String) -> String? {
        let c = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let m = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = m.lowercased()

        switch c {
        case "RATE_LIMITED":
            return "Çok hızlı istek gönderildi. Güvenlik için kısa bir süre bekleyip tekrar dene."
        case "USAGE_LIMIT_EXCEEDED", "DAILY_LIMIT_EXCEEDED", "DAILY_STORY_LIMIT", "STORY_LIMIT_REACHED",
             "STORY_QUOTA_EXCEEDED", "QUOTA_EXCEEDED", "USAGE_LIMIT", "MASA_LIMIT", "MASAL_LIMIT", "STORY_LIMIT",
             "DAILY_USAGE_EXCEEDED":
            return "Bugün için masal limitine ulaştın. Limit yenilendiğinde veya uygun aboneliğinle tekrar deneyebilirsin."
        case "SUBSCRIPTION_REQUIRED", "PAYMENT_REQUIRED", "PREMIUM_REQUIRED":
            return "Bu işlem için uygun bir abonelik gerekebilir. Abonelik ekranından seçeneklere bakabilirsin."
        case "INTERNAL_SERVER_ERROR":
            return "Sunucuda beklenmeyen bir sorun oluştu. Kısa bir süre sonra tekrar dene."
        case "OPENAI_TIMEOUT":
            return "Masal üretimi bu denemede zaman aşımına uğradı. Lütfen tekrar deneyin."
        case "OPENAI_RATE_LIMITED":
            return "Masal servisi yoğun. Birkaç saniye sonra tekrar deneyin."
        case "OPENAI_CONFIG_ERROR":
            return "Masal servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin."
        case "OPENAI_MODEL_NOT_FOUND":
            return "Masal servisi model ayarı geçersiz. Lütfen destek ile iletişime geçin."
        case "OPENAI_PROMPT_TOO_LONG":
            return "Masal isteği çok uzun. Lütfen ek detayları biraz kısaltıp tekrar deneyin."
        case "OPENAI_UPSTREAM_ERROR":
            return "Masal servisi şu an meşgul. Lütfen birazdan tekrar deneyin."
        case "CHILD_NOT_FOUND":
            return "Çocuk profili bulunamadı. Profilinden çocuğunu seç veya yeniden ekle, sonra tekrar dene."
        case "CHILD_LIMIT_EXCEEDED", "MAX_CHILDREN", "MAX_CHILDREN_REACHED", "CHILD_LIMIT":
            return "Ekleyebileceğin çocuk profili sayısı sınırına ulaşıldı. Mevcut profillerden birini düzenleyebilir veya destek ile iletişime geçebilirsin."
        case "NOT_FOUND":
            if Self.messageSuggestsChildIssue(lower) {
                return "Çocuk profili bulunamadı. Profilinden çocuğunu seç veya yeniden ekle, sonra tekrar dene."
            }
        default:
            break
        }

        if lower.contains("rate limit") {
            return "Çok hızlı istek gönderildi. Güvenlik için kısa bir süre bekleyip tekrar dene."
        }
        if Self.messageSuggestsStoryUsageLimit(lower) {
            return "Bugün için masal limitine ulaştın. Limit yenilendiğinde veya uygun aboneliğinle tekrar deneyebilirsin."
        }
        if Self.messageSuggestsChildIssue(lower) {
            return Self.turkishMessageForChildHeuristic(lower)
        }
        return nil
    }

    private static func messageSuggestsStoryUsageLimit(_ lower: String) -> Bool {
        let usageHints = lower.contains("usage") || lower.contains("quota") || lower.contains("daily limit")
            || lower.contains("günlük") || lower.contains("kotan")
        let storyHints = lower.contains("story") || lower.contains("masal")
        let limitHints = lower.contains("limit") || lower.contains("exceeded") || lower.contains("aşıldı")
            || lower.contains("doldu")
        return (usageHints && limitHints) || (storyHints && limitHints) || (lower.contains("429") && storyHints)
    }

    private static func messageSuggestsChildIssue(_ lower: String) -> Bool {
        lower.contains("child") || lower.contains("çocuk")
    }

    private static func turkishMessageForChildHeuristic(_ lower: String) -> String {
        if lower.contains("not found") || lower.contains("bulunamad") || lower.contains("unknown child")
            || lower.contains("invalid child") || lower.contains("no such child") {
            return "Çocuk profili bulunamadı veya artık geçerli değil. Profilden çocuğunu seçerek tekrar dene."
        }
        if lower.contains("limit") || lower.contains("maximum") || lower.contains("sınır") || lower.contains("too many") {
            return "Ekleyebileceğin çocuk profili sayısı sınırına ulaşıldı."
        }
        return "Çocuk profiliyle ilgili bir işlem tamamlanamadı. Bilgileri kontrol edip tekrar dene."
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let requestBuilder: AuthenticatedRequestBuilder
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = AppConfig.backendBaseURL,
        requestBuilder: AuthenticatedRequestBuilder = AuthenticatedRequestBuilder()
    ) {
        self.baseURL = baseURL
        self.requestBuilder = requestBuilder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws -> T {
        let bodyData: Data?
        if let body {
            bodyData = try encode(body)
        } else {
            bodyData = nil
        }

        let request = try await requestBuilder.build(baseURL: baseURL, endpoint: endpoint, jsonBody: bodyData)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw APIClientError.networkFailure(Self.describeURLError(error))
        } catch {
            throw APIClientError.networkFailure("Ağ bağlantısında bir sorun oluştu. Lütfen tekrar deneyin.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if http.statusCode == 401 {
            throw APIClientError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
               let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            throw APIClientError.invalidResponse
        }

        guard !data.isEmpty else {
            throw APIClientError.emptyData
        }

        do {
            let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
            if envelope.success == false, let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            if let value = envelope.data {
                return value
            }
            throw APIClientError.decodingFailed
        } catch let err as APIClientError {
            throw err
        } catch {
            throw APIClientError.decodingFailed
        }
    }

    /// Bearer token olmadan (giriş öncesi) JSON isteği — örn. `POST /v1/auth/forgot-password`.
    func requestWithoutAuthentication<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws -> T {
        let bodyData: Data?
        if let body {
            bodyData = try encode(body)
        } else {
            bodyData = nil
        }

        let request = try requestBuilder.buildPublic(baseURL: baseURL, endpoint: endpoint, jsonBody: bodyData)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw APIClientError.networkFailure(Self.describeURLError(error))
        } catch {
            throw APIClientError.networkFailure("Ağ bağlantısında bir sorun oluştu. Lütfen tekrar deneyin.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
               let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            throw APIClientError.invalidResponse
        }

        guard !data.isEmpty else {
            throw APIClientError.emptyData
        }

        do {
            let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
            if envelope.success == false, let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            if let value = envelope.data {
                return value
            }
            throw APIClientError.decodingFailed
        } catch let err as APIClientError {
            throw err
        } catch {
            throw APIClientError.decodingFailed
        }
    }

    /// `multipart/form-data` ile dosya yükler (ör. `POST /v1/classic-tales/{taleId}/audio`, alan adı `file`).
    func uploadMultipart<T: Decodable>(
        _ endpoint: APIEndpoint,
        fileURL: URL,
        fieldName: String = "file",
        mimeType: String = "audio/mpeg"
    ) async throws -> T {
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw APIClientError.networkFailure("Ses dosyası okunamadı.")
        }

        let filename = fileURL.lastPathComponent
        let request = try await requestBuilder.buildMultipartFileUpload(
            baseURL: baseURL,
            endpoint: endpoint,
            fileData: fileData,
            fieldName: fieldName,
            filename: filename,
            mimeType: mimeType
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw APIClientError.networkFailure(Self.describeURLError(error))
        } catch {
            throw APIClientError.networkFailure("Ağ bağlantısında bir sorun oluştu. Lütfen tekrar deneyin.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if http.statusCode == 401 {
            throw APIClientError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
               let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            throw APIClientError.invalidResponse
        }

        guard !data.isEmpty else {
            throw APIClientError.emptyData
        }

        do {
            let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
            if envelope.success == false, let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            if let value = envelope.data {
                return value
            }
            throw APIClientError.decodingFailed
        } catch let err as APIClientError {
            throw err
        } catch {
            throw APIClientError.decodingFailed
        }
    }

    private func encode(_ value: Encodable) throws -> Data {
        return try encoder.encode(AnyEncodable(value))
    }

    private static func describeURLError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin."
        case .cannotFindHost, .dnsLookupFailed:
            return "Sunucu adresi çözülemedi. Lütfen daha sonra tekrar deneyin."
        case .timedOut:
            return "İstek zaman aşımına uğradı. Lütfen tekrar deneyin."
        case .secureConnectionFailed, .serverCertificateUntrusted:
            return "Güvenli bağlantı kurulamadı (HTTPS/sertifika)."
        case .appTransportSecurityRequiresSecureConnection:
            return "Güvenli bağlantı gereksinimi nedeniyle istek engellendi."
        default:
            return "Ağ bağlantısında bir sorun oluştu. Lütfen tekrar deneyin."
        }
    }
}

private struct EmptyData: Decodable {}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeFunc = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

