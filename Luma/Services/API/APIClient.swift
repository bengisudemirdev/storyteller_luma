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
            if code == "RATE_LIMITED" {
                return "Şu an çok fazla istek gönderildi. Güvenlik için kısa bir süre bekleyip tekrar dene."
            }
            if code == "INTERNAL_SERVER_ERROR" {
                return "Sunucuda beklenmeyen bir sorun oluştu. Kısa bir süre sonra tekrar dene."
            }
            if code == "OPENAI_TIMEOUT" {
                return "Masal üretimi bu denemede zaman aşımına uğradı. Lütfen tekrar deneyin."
            }
            if code == "OPENAI_RATE_LIMITED" {
                return "Masal servisi yoğun. Birkaç saniye sonra tekrar deneyin."
            }
            if code == "OPENAI_CONFIG_ERROR" {
                return "Masal servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin."
            }
            if message.localizedCaseInsensitiveContains("rate limit") {
                return "Şu an çok fazla istek gönderildi. Güvenlik için kısa bir süre bekleyip tekrar dene."
            }
            return message
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
            throw APIClientError.networkFailure(error.localizedDescription)
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
            if let value = envelope.data {
                return value
            }
            throw APIClientError.decodingFailed
        } catch {
            throw APIClientError.decodingFailed
        }
    }

    private func encode(_ value: Encodable) throws -> Data {
        return try encoder.encode(AnyEncodable(value))
    }

    private static func describeURLError(_ error: URLError) -> String {
        let base = error.localizedDescription
        switch error.code {
        case .notConnectedToInternet:
            return "İnternet bağlantısı yok. \(base)"
        case .cannotFindHost, .dnsLookupFailed:
            return "Sunucu adresi çözülemedi. BACKEND_BASE_URL’i kontrol edin. \(base)"
        case .timedOut:
            return "İstek zaman aşımına uğradı. Backend çalışıyor mu? \(base)"
        case .secureConnectionFailed, .serverCertificateUntrusted:
            return "Güvenli bağlantı kurulamadı (HTTPS/sertifika). \(base)"
        case .appTransportSecurityRequiresSecureConnection:
            return "ATS: HTTP API engellendi. HTTPS kullanın veya yerel ağ için Info.plist’te NSAllowsLocalNetworking açık olsun. \(base)"
        default:
            return base
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

