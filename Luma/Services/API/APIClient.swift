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

private struct APIEnvelopeSparse: Decodable {
    let success: Bool?
    let error: APIErrorPayload?
}

enum APIClientError: LocalizedError {
    case invalidURL
    case unauthorized
    /// HTTP 402 — ödeme / hak; gövdedeki API `code` (varsa) ayrı taşınır.
    case paymentRequired(apiCode: String?, message: String?)
    case server(code: String, message: String)
    case decodingFailed
    case invalidResponse
    case emptyData
    /// Sunucuya ulaşılamıyor (ATS, yanlış URL, kapalı backend, DNS vb.).
    case networkFailure(String)

    var serverErrorCode: String? {
        switch self {
        case .server(let code, _):
            return code.uppercased()
        case .paymentRequired(let apiCode, _):
            return apiCode?.uppercased()
        default:
            return nil
        }
    }

    var isInsufficientCredits: Bool {
        serverErrorCode == "INSUFFICIENT_CREDITS"
    }

    /// Yanıt düşmese de masal kaydedilmiş olabileceği için `GET /v1/stories` ile kurtarma denenebilir.
    var allowsStoryGenerateListRecovery: Bool {
        switch self {
        case .decodingFailed, .invalidResponse, .emptyData:
            return true
        case .networkFailure(let msg):
            let lower = msg.lowercased()
            return lower.contains("timeout") || lower.contains("timed out") || lower.contains("zaman aşımı")
        case .server(let code, _):
            let c = code.uppercased()
            return [
                "STORY_GENERATE_FAILED", "REQUEST_TIMEOUT", "GATEWAY_TIMEOUT", "OPENAI_TIMEOUT",
                "BAD_GATEWAY", "SERVICE_UNAVAILABLE", "INTERNAL_SERVER_ERROR", "OPENAI_UPSTREAM_ERROR",
                "OPENAI_REQUEST_FAILED"
            ].contains(c)
        case .paymentRequired:
            return false
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz API URL."
        case .unauthorized:
            return "Yetkilendirme başarısız. Lütfen tekrar giriş yapın."
        case .paymentRequired(let apiCode, _):
            switch apiCode?.uppercased() {
            case "STORY_LIMIT_REACHED":
                return "Masal hakkın doldu. Hakkın yenilendiğinde tekrar deneyebilirsin."
            case "VOICE_LIMIT_REACHED":
                return "Sesli masal hakkın doldu."
            default:
                return "Bu işlem için uygun bir abonelik veya hak gerekiyor."
            }
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
            return "Masal hakkına ulaştın. Hakkın yenilendiğinde veya planını yükselttiğinde tekrar deneyebilirsin."
        case "SUBSCRIPTION_REQUIRED", "PAYMENT_REQUIRED", "PREMIUM_REQUIRED":
            return "Bu işlem için uygun bir abonelik gerekebilir. Abonelik ekranından seçeneklere bakabilirsin."
        case "INSUFFICIENT_CREDITS":
            return "Bu işlem için kullanım hakkın yetersiz."
        case "INTERNAL_SERVER_ERROR":
            return "Sunucuda beklenmeyen bir sorun oluştu. Kısa bir süre sonra tekrar dene."
        case "CONTENT_UNSAFE", "UNSAFE_CONTENT", "CONTENT_POLICY_VIOLATION":
            return "Üretilen masal metni güvenlik filtresine takıldı (ek açıklama yazmasanız da olabilir). Farklı bir tema deneyin veya bir süre sonra tekrar oluşturmayı deneyin."
        case "STORY_GENERATE_FAILED", "GENERATION_FAILED", "OPENAI_GENERATION_FAILED":
            return "Masal oluşturulurken bir sorun oluştu. Biraz sonra tekrar dene veya farklı bir tema seçerek yeniden dene."
        case "OPENAI_TIMEOUT":
            return "Masal üretimi bu denemede zaman aşımına uğradı. Lütfen tekrar deneyin."
        case "OPENAI_RATE_LIMITED":
            return "Masal servisi yoğun. Birkaç saniye sonra tekrar deneyin."
        case "OPENAI_CONFIG_ERROR":
            return "Masal servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin."
        case "MINIMAX_INSUFFICIENT_BALANCE", "MINIMAX_NOT_CONFIGURED":
            return "Seslendirme servisi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin."
        case "MINIMAX_TTS_TIMEOUT":
            return "Seslendirme bu denemede zaman aşımına uğradı. Lütfen tekrar deneyin."
        case "MINIMAX_TTS_FAILED", "MINIMAX_AUDIO_MISSING", "MINIMAX_AUDIO_FETCH_FAILED", "AUDIO_UPLOAD_FAILED":
            return "Seslendirme oluşturulurken bir sorun oluştu. Lütfen biraz sonra tekrar deneyin."
        case "OPENAI_MODEL_NOT_FOUND":
            return "Masal servisi model ayarı geçersiz. Lütfen destek ile iletişime geçin."
        case "OPENAI_PROMPT_TOO_LONG":
            return "Masal isteği çok uzun. Lütfen ek detayları biraz kısaltıp tekrar deneyin."
        case "OPENAI_UPSTREAM_ERROR":
            return "Masal servisi şu an meşgul. Lütfen birazdan tekrar deneyin."
        case "CHILD_NOT_FOUND":
            return "Çocuk profili bulunamadı. Profilinden çocuğunu seç veya yeniden ekle, sonra tekrar dene."
        case "CHILD_LIMIT_EXCEEDED", "CHILD_PROFILE_LIMIT_REACHED", "MAX_CHILDREN", "MAX_CHILDREN_REACHED", "CHILD_LIMIT":
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
            return "Masal hakkına ulaştın. Hakkın yenilendiğinde veya planını yükselttiğinde tekrar deneyebilirsin."
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

    /// `POST /v1/stories/generate` — üretim sunucuda sürebilir; kurtarma için liste ile tamamlanır.
    static let storyGenerateURLSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 90
        cfg.timeoutIntervalForResource = 120
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

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
        body: Encodable? = nil,
        urlSession customSession: URLSession? = nil
    ) async throws -> T {
        let bodyData: Data?
        if let body {
            bodyData = try encode(body)
        } else {
            bodyData = nil
        }

        let request = try await requestBuilder.build(baseURL: baseURL, endpoint: endpoint, jsonBody: bodyData)
        let session = customSession ?? URLSession.shared

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
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
            if http.statusCode == 402 {
                if let sparse = try? decoder.decode(APIEnvelopeSparse.self, from: data),
                   sparse.success == false,
                   let apiError = sparse.error {
                    throw APIClientError.paymentRequired(apiCode: apiError.code, message: apiError.message)
                }
                if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
                   let apiError = envelope.error {
                    throw APIClientError.paymentRequired(apiCode: apiError.code, message: apiError.message)
                }
                throw APIClientError.paymentRequired(apiCode: nil, message: nil)
            }
            if let sparse = try? decoder.decode(APIEnvelopeSparse.self, from: data),
               sparse.success == false,
               let apiError = sparse.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
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
            Self.logDecodingFailure(
                endpointPath: endpoint.path,
                statusCode: http.statusCode,
                data: data,
                underlying: NSError(domain: "LumaAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "API envelope decoded but data was nil"])
            )
            throw APIClientError.decodingFailed
        } catch let err as APIClientError {
            throw err
        } catch {
            Self.logDecodingFailure(endpointPath: endpoint.path, statusCode: http.statusCode, data: data, underlying: error)
            throw APIClientError.decodingFailed
        }
    }

    /// Başarılı HTTP gövdesini model çözümlemeden döndürür; gövdede `success: false` ise `APIClientError.server` fırlatır.
    func requestRawSuccessData(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        urlSession customSession: URLSession? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let bodyData: Data?
        if let body {
            bodyData = try encode(body)
        } else {
            bodyData = nil
        }

        let request = try await requestBuilder.build(baseURL: baseURL, endpoint: endpoint, jsonBody: bodyData)
        let session = customSession ?? URLSession.shared

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
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
            if http.statusCode == 402 {
                if let sparse = try? decoder.decode(APIEnvelopeSparse.self, from: data),
                   sparse.success == false,
                   let apiError = sparse.error {
                    throw APIClientError.paymentRequired(apiCode: apiError.code, message: apiError.message)
                }
                if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
                   let apiError = envelope.error {
                    throw APIClientError.paymentRequired(apiCode: apiError.code, message: apiError.message)
                }
                throw APIClientError.paymentRequired(apiCode: nil, message: nil)
            }
            if let sparse = try? decoder.decode(APIEnvelopeSparse.self, from: data),
               sparse.success == false,
               let apiError = sparse.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
               let apiError = envelope.error {
                throw APIClientError.server(code: apiError.code, message: apiError.message)
            }
            throw APIClientError.invalidResponse
        }

        guard !data.isEmpty else {
            throw APIClientError.emptyData
        }

        if let sparse = try? decoder.decode(APIEnvelopeSparse.self, from: data),
           sparse.success == false,
           let apiError = sparse.error {
            throw APIClientError.server(code: apiError.code, message: apiError.message)
        }

        return (data, http)
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
            if http.statusCode == 402 {
                if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
                   let apiError = envelope.error {
                    throw APIClientError.paymentRequired(apiCode: apiError.code, message: apiError.message)
                }
                throw APIClientError.paymentRequired(apiCode: nil, message: nil)
            }
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
            Self.logDecodingFailure(endpointPath: endpoint.path, statusCode: http.statusCode, data: data, underlying: error)
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
            if http.statusCode == 402 {
                if let envelope = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data),
                   let apiError = envelope.error {
                    throw APIClientError.paymentRequired(apiCode: apiError.code, message: apiError.message)
                }
                throw APIClientError.paymentRequired(apiCode: nil, message: nil)
            }
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
            Self.logDecodingFailure(endpointPath: endpoint.path, statusCode: http.statusCode, data: data, underlying: error)
            throw APIClientError.decodingFailed
        }
    }

    private static func logDecodingFailure(endpointPath: String, statusCode: Int, data: Data, underlying: Error) {
        let preview = String(data: data.prefix(1000), encoding: .utf8) ?? "<binary>"
        AppLogger.error("api.response.decode_failed", [
            "path": endpointPath,
            "statusCode": "\(statusCode)",
            "responseBodyPreview": preview,
            "decodingError": String(describing: underlying)
        ])
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
            return "İstek zaman aşımına uğradı. Masal üretimi uzun sürdüyse bir kez daha dene; internet bağlantını kontrol et."
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
