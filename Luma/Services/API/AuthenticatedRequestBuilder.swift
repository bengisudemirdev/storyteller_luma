import Foundation

struct AuthenticatedRequestBuilder {
    private let sessionProvider: AuthSessionProviding

    init(sessionProvider: AuthSessionProviding = AuthSessionProvider.shared) {
        self.sessionProvider = sessionProvider
    }

    /// `appendingPathComponent("/v1/children")` çok segmentli path’i tek parça sanıp `%2F` üretebiliyor; API URL’lerini güvenle birleştirir.
    private static func makeRequestURL(baseURL: URL, path: String, queryItems: [URLQueryItem]) throws -> URL {
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await sessionProvider.accessToken()
        #if DEBUG
        print("[Olia DEBUG] Authorization: Bearer \(token)")
        print("[Olia DEBUG] İstek: \(endpoint.method.rawValue) \(endpoint.path)")
        #endif
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }
}

