import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    /// İstek seviyesinde timeout. `nil` ise sistem varsayılanı kullanılır.
    let timeoutInterval: TimeInterval?

    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        timeoutInterval: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.timeoutInterval = timeoutInterval
    }
}

