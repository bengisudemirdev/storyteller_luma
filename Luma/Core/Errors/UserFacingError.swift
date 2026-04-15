import Foundation

extension Error {
    var userFacingTurkishMessage: String {
        if let apiError = self as? APIClientError {
            return apiError.errorDescription ?? "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."
        }

        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain {
            let urlCode = URLError.Code(rawValue: nsError.code)
            switch urlCode {
            case .notConnectedToInternet:
                return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin."
            case .timedOut:
                return "İstek zaman aşımına uğradı. Lütfen tekrar deneyin."
            case .cannotFindHost, .dnsLookupFailed:
                return "Sunucu adresine ulaşılamadı. Lütfen daha sonra tekrar deneyin."
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return "Güvenli bağlantı kurulamadı. Lütfen daha sonra tekrar deneyin."
            default:
                return "Ağ bağlantısında bir sorun oluştu. Lütfen tekrar deneyin."
            }
        }

        return "Bir hata oluştu. Lütfen tekrar deneyin."
    }
}
