import Foundation

struct AuthenticatedRequestBuilder {
    static let defaultTimeout: TimeInterval = 20

    private let sessionProvider: AuthSessionProviding

    init(sessionProvider: AuthSessionProviding = AuthSessionProvider.shared) {
        self.sessionProvider = sessionProvider
    }

    /// `appendingPathComponent("/v1/children")` çok segmentli path’i tek parça sanıp `%2F` üretebiliyor; API URL’lerini güvenle birleştirir.
    static func makeRequestURL(baseURL: URL, path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIClientError.invalidURL
        }
        let suffix = path.hasPrefix("/") ? path : "/\(path)"
        let existing = components.path
        let merged: String
        if existing.isEmpty || existing == "/" {
            merged = suffix
        } else {
            let left = existing.hasSuffix("/") ? String(existing.dropLast()) : existing
            merged = (left + suffix).replacingOccurrences(of: "//", with: "/")
        }
        components.path = merged
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIClientError.invalidURL
        }
        return url
    }

    func build(
        baseURL: URL,
        endpoint: APIEndpoint,
        jsonBody: Data?
    ) async throws -> URLRequest {
        let url = try Self.makeRequestURL(
            baseURL: baseURL,
            path: endpoint.path,
            queryItems: endpoint.queryItems
        )

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = jsonBody
        // Sistem varsayılanı 60 sn; yavaş/kapalı sunucuda arayüz bu kadar bekliyormuş gibi görünüyordu.
        // Uzun süren uçlar (masal üretimi, seslendirme) kendi zaman aşımını belirtir.
        request.timeoutInterval = endpoint.timeoutInterval ?? AuthenticatedRequestBuilder.defaultTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await sessionProvider.accessToken()
        #if DEBUG
        print("[Olia DEBUG] Authorization: Bearer \(Self.redactedToken(token))")
        print("[Olia DEBUG] İstek: \(endpoint.method.rawValue) \(endpoint.path)")
        #endif
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    /// `multipart/form-data` (ör. `POST /v1/classic-tales/{id}/audio`). `Content-Type` sınırı URLSession’ın üreteceği biçimdedir.
    func buildMultipartFileUpload(
        baseURL: URL,
        endpoint: APIEndpoint,
        fileData: Data,
        fieldName: String,
        filename: String,
        mimeType: String
    ) async throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = Self.multipartBody(
            fileData: fileData,
            boundary: boundary,
            fieldName: fieldName,
            filename: filename,
            mimeType: mimeType
        )

        let url = try Self.makeRequestURL(
            baseURL: baseURL,
            path: endpoint.path,
            queryItems: endpoint.queryItems
        )

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = body
        // Sistem varsayılanı 60 sn; yavaş/kapalı sunucuda arayüz bu kadar bekliyormuş gibi görünüyordu.
        // Uzun süren uçlar (masal üretimi, seslendirme) kendi zaman aşımını belirtir.
        request.timeoutInterval = endpoint.timeoutInterval ?? AuthenticatedRequestBuilder.defaultTimeout
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await sessionProvider.accessToken()
        #if DEBUG
        print("[Olia DEBUG] Authorization: Bearer \(Self.redactedToken(token))")
        print("[Olia DEBUG] İstek (multipart): \(endpoint.method.rawValue) \(endpoint.path)")
        #endif
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    /// Giriş öncesi uçlar (`/v1/auth/forgot-password` vb.) için Bearer kullanılmaz.
    func buildPublic(baseURL: URL, endpoint: APIEndpoint, jsonBody: Data?) throws -> URLRequest {
        let url = try Self.makeRequestURL(
            baseURL: baseURL,
            path: endpoint.path,
            queryItems: endpoint.queryItems
        )

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = jsonBody
        // Sistem varsayılanı 60 sn; yavaş/kapalı sunucuda arayüz bu kadar bekliyormuş gibi görünüyordu.
        // Uzun süren uçlar (masal üretimi, seslendirme) kendi zaman aşımını belirtir.
        request.timeoutInterval = endpoint.timeoutInterval ?? AuthenticatedRequestBuilder.defaultTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return request
    }

    private static func redactedToken(_ token: String) -> String {
        guard token.count > 16 else { return "REDACTED" }
        let prefix = token.prefix(8)
        let suffix = token.suffix(8)
        return "\(prefix)...\(suffix)"
    }

    private static func multipartBody(
        fileData: Data,
        boundary: String,
        fieldName: String,
        filename: String,
        mimeType: String
    ) -> Data {
        var data = Data()
        let prefix = "--\(boundary)\r\n"
            + "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n"
            + "Content-Type: \(mimeType)\r\n\r\n"
        data.append(Data(prefix.utf8))
        data.append(fileData)
        data.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return data
    }
}

