import Foundation
import UIKit

/// `POST /v1/feedback`: geri bildirimi uygulama içinden sunucuya gönderir (e-posta uygulamasına yönlendirme yok).
enum FeedbackAPIService {
    private struct Payload: Encodable {
        let message: String
        let appVersion: String
        let osVersion: String
        let deviceModel: String
    }

    private struct Response: Decodable {
        let id: String
    }

    static func send(message: String) async throws {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        let payload = Payload(
            message: message,
            appVersion: build.isEmpty ? version : "\(version) (\(build))",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: Self.deviceModelIdentifier()
        )
        let endpoint = APIEndpoint(path: "/v1/feedback", method: .post, timeoutInterval: 20)
        let _: Response = try await APIClient.shared.request(endpoint, body: payload)
    }

    /// "iPhone17,1" gibi model tanımlayıcısı (kişisel veri içermez).
    private static func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}
