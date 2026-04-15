import AVFoundation
import Foundation

// MARK: - API types

struct ElevenLabsAgentResponse: Decodable {
    let conversation_config: ConversationConfig

    struct ConversationConfig: Decodable {
        let tts: TTSConfig
    }

    struct TTSConfig: Decodable {
        let voice_id: String
        let model_id: String?
        let voice_settings: VoiceSettings?
    }

    struct VoiceSettings: Decodable {
        let stability: Double?
        let similarity_boost: Double?
        let style: Double?
        let use_speaker_boost: Bool?
        let speed: Double?

        var asDictionary: [String: Any] {
            var dict: [String: Any] = [:]
            if let stability { dict["stability"] = stability }
            if let similarity_boost { dict["similarity_boost"] = similarity_boost }
            if let style { dict["style"] = style }
            if let use_speaker_boost { dict["use_speaker_boost"] = use_speaker_boost }
            if let speed { dict["speed"] = speed }
            return dict
        }
    }
}

enum ElevenLabsNarrationError: LocalizedError {
    case invalidURL
    case http(Int, String?)
    case missingVoiceId
    case emptyText

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "ElevenLabs isteği oluşturulamadı."
        case let .http(code, body):
            if let body, !body.isEmpty { return "ElevenLabs (\(code)): \(body)" }
            return "ElevenLabs hata kodu: \(code)"
        case .missingVoiceId:
            return "Agent yapılandırmasında voice_id bulunamadı."
        case .emptyText:
            return "Seslendirilecek metin yok."
        }
    }
}

/// Convai agent üzerinden `voice_id` alır, klasik TTS ile MP3 üretir (HTTPS `api.elevenlabs.io`).
enum ElevenLabsNarrationService {
    private static let apiHost = "api.elevenlabs.io"

    private static var cachedVoice: (agentId: String, voiceId: String, modelId: String, voiceSettings: ElevenLabsAgentResponse.VoiceSettings?)?

    /// Agent API'den ses ve model bilgisi (oturum boyunca önbelleklenir).
    static func resolveVoiceAndModel(
        apiKey: String,
        agentId: String
    ) async throws -> (
        voiceId: String,
        modelId: String,
        voiceSettings: ElevenLabsAgentResponse.VoiceSettings?
    ) {
        let normalizedAgentId = normalizeAgentId(agentId)
        if let c = cachedVoice, c.agentId == normalizedAgentId {
            return (c.voiceId, c.modelId, c.voiceSettings)
        }
        let enc = normalizedAgentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? normalizedAgentId
        guard let url = URL(string: "https://\(apiHost)/v1/convai/agents/\(enc)") else {
            throw ElevenLabsNarrationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(ElevenLabsAgentResponse.self, from: data)
        let voiceId = decoded.conversation_config.tts.voice_id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !voiceId.isEmpty else { throw ElevenLabsNarrationError.missingVoiceId }

        let modelId = sanitizedModelId(decoded.conversation_config.tts.model_id)
        let voiceSettings = decoded.conversation_config.tts.voice_settings
        cachedVoice = (normalizedAgentId, voiceId, modelId, voiceSettings)
        return (voiceId, modelId, voiceSettings)
    }

    /// Uzun metinleri TTS limitine göre böler, her parça için MP3 indirir, geçici dosya URL'leri döner.
    static func synthesizeToTempFiles(
        text: String,
        apiKey: String,
        voiceId: String,
        modelId: String,
        voiceSettings: ElevenLabsAgentResponse.VoiceSettings?
    ) async throws -> [URL] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ElevenLabsNarrationError.emptyText }

        let chunks = chunkText(trimmed, maxLength: 4000)
        var urls: [URL] = []
        for (index, chunk) in chunks.enumerated() {
            try Task.checkCancellation()
            let data = try await requestSpeechData(
                text: chunk,
                apiKey: apiKey,
                voiceId: voiceId,
                modelId: modelId,
                voiceSettings: voiceSettings
            )
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("luma_elevenlabs_\(UUID().uuidString)_\(index).mp3")
            try data.write(to: tmp, options: .atomic)
            urls.append(tmp)
        }
        return urls
    }

    private static func requestSpeechData(
        text: String,
        apiKey: String,
        voiceId: String,
        modelId: String,
        voiceSettings: ElevenLabsAgentResponse.VoiceSettings?
    ) async throws -> Data {
        let vEnc = voiceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? voiceId
        var components = URLComponents()
        components.scheme = "https"
        components.host = apiHost
        components.path = "/v1/text-to-speech/\(vEnc)"
        components.queryItems = [URLQueryItem(name: "output_format", value: "mp3_44100_128")]
        guard let url = components.url else { throw ElevenLabsNarrationError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "text": text,
            "model_id": modelId
        ]
        if let voiceSettings {
            let settings = voiceSettings.asDictionary
            if !settings.isEmpty {
                body["voice_settings"] = settings
            }
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200 ... 299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8)
            throw ElevenLabsNarrationError.http(http.statusCode, snippet)
        }
    }

    /// Convai TTS model adı bazen klasik `text-to-speech` ile uyumsuz olabilir; güvenli varsayılan kullan.
    private static func sanitizedModelId(_ raw: String?) -> String {
        let fallback = "eleven_multilingual_v2"
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return fallback
        }
        if raw.contains("v3_conversational") || raw == "eleven_v3_conversational" {
            return fallback
        }
        return raw
    }

    private static func chunkText(_ text: String, maxLength: Int) -> [String] {
        guard text.count > maxLength else { return [text] }
        var result: [String] = []
        var remaining = text

        while !remaining.isEmpty {
            if remaining.count <= maxLength {
                result.append(remaining.trimmingCharacters(in: .whitespacesAndNewlines))
                break
            }
            let endIdx = remaining.index(remaining.startIndex, offsetBy: maxLength)
            let window = String(remaining[..<endIdx])
            if let range = window.range(of: ". ", options: .backwards) {
                let cut = window[..<range.upperBound]
                let piece = String(cut).trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty { result.append(piece) }
                remaining = String(remaining[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let sp = window.lastIndex(of: " ") {
                let cut = String(remaining[..<sp])
                let piece = cut.trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty { result.append(piece) }
                remaining = String(remaining[remaining.index(after: sp)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                let piece = window.trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty { result.append(piece) }
                remaining = String(remaining[endIdx...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return result.filter { !$0.isEmpty }
    }

    private static func normalizeAgentId(_ raw: String) -> String {
        var value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

        // URL ya da path yapıştıysa sadece son segmenti al.
        if let slash = value.lastIndex(of: "/"), slash < value.index(before: value.endIndex) {
            value = String(value[value.index(after: slash)...])
        }

        // Sondaki .git / git gibi yapışmış ekleri temizle.
        if value.hasSuffix(".git") {
            value = String(value.dropLast(4))
        }
        if value.hasPrefix("agent_"), value.hasSuffix("git"), value.count > 30 {
            value = String(value.dropLast(3))
        }

        // Non-agent metnin içinden güvenli şekilde agent token'ını çek.
        if let range = value.range(of: #"agent_[a-zA-Z0-9]+"#, options: .regularExpression) {
            value = String(value[range])
        }

        // Noktalama/boşluk artıkları.
        while let last = value.unicodeScalars.last,
              !(CharacterSet.alphanumerics.contains(last) || last == "_") {
            value.removeLast()
        }
        return value
    }
}

// MARK: - Playback (sıralı MP3)

@MainActor
final class ElevenLabsSequentialPlayer: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?
    private var pendingTempFiles: [URL] = []

    /// Sırayla MP3 çalar; üst seviyedeki `Task` iptal edildiğinde `checkCancellation` ile durur.
    func play(urls: [URL]) async throws {
        stop()
        guard !urls.isEmpty else { return }
        pendingTempFiles = urls
        defer { cleanupTempAll() }
        await activateSession()
        for url in urls {
            try Task.checkCancellation()
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                self.continuation = cont
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.delegate = self
                    self.audioPlayer = player
                    if player.play() { return }
                } catch {
                    AppLogger.error("elevenlabs.audioPlay", ["error": String(describing: error)])
                }
                cont.resume()
            }
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        continuation?.resume()
        continuation = nil
        cleanupTempAll()
    }

    private func activateSession() async {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            AppLogger.error("elevenlabs.audioSession", ["error": String(describing: error)])
        }
    }

    private func cleanupTempAll() {
        for url in pendingTempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        pendingTempFiles = []
    }
}

extension ElevenLabsSequentialPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.audioPlayer = nil
            self.continuation?.resume()
            self.continuation = nil
        }
    }
}
