import AVFoundation
import Combine

/// Uygulama genelinde masal seslendirmesi: mini panel + kuyruk oynatıcı / AVSpeech.
@MainActor
final class NarrationPlaybackCenter: NSObject, ObservableObject {
    static let shared = NarrationPlaybackCenter()

    @Published var isPanelVisible = false
    @Published var displayTitle: String = ""
    @Published var isLoading = false
    @Published var isPaused = false
    /// ElevenLabs veya AVSpeech oturumu açık mı (panel göstermek için).
    @Published private(set) var isSessionActive = false

    private let queuePlayer = NarrationQueuePlayer()
    private let speechSynth = AVSpeechSynthesizer()
    private var elevenLabsTask: Task<Void, Never>?

    private var activeContentKey: String = ""
    private var avSpeechText: String = ""
    private var avSpeechPaused = false
    private var engine: Engine = .none

    private enum Engine {
        case none
        case queue
        case avSpeech
    }

    private override init() {
        super.init()
        speechSynth.delegate = self
    }

    // MARK: - Kimlik (aynı içerikte duraklat / sürdür)

    func contentKey(text: String, classicTaleCacheId: String?) -> String {
        if let id = classicTaleCacheId, !id.isEmpty {
            return "classic:\(id)"
        }
        return "text:\(text.hashValue)"
    }

    func isSameSession(text: String, classicTaleCacheId: String?) -> Bool {
        contentKey(text: text, classicTaleCacheId: classicTaleCacheId) == activeContentKey
    }

    // MARK: - Başlat / durdur

    func toggleOrStart(text: String, displayTitle: String, classicTaleCacheId: String?) {
        let key = contentKey(text: text, classicTaleCacheId: classicTaleCacheId)
        if isSessionActive && activeContentKey == key {
            if isLoading {
                stopEverything()
                return
            }
            togglePauseResume()
            return
        }

        stopEverything()
        activeContentKey = key
        self.displayTitle = displayTitle

        if AppConfig.isElevenLabsNarrationConfigured {
            isSessionActive = true
            isPanelVisible = true
            isLoading = true
            engine = .queue
            elevenLabsTask = Task { [weak self] in
                await self?.runElevenLabs(text: text, classicTaleCacheId: classicTaleCacheId)
            }
        } else {
            startAVSpeech(text: text)
        }
    }

    /// Toolbar / mini oynatıcı: çalıyorsa duraklat ikonu göster.
    var transportShowsPause: Bool {
        switch engine {
        case .queue:
            return queuePlayer.isPlaying
        case .avSpeech:
            return speechSynth.isSpeaking && !avSpeechPaused
        case .none:
            return false
        }
    }

    func togglePauseResume() {
        switch engine {
        case .queue:
            if queuePlayer.isPlaying {
                queuePlayer.pause()
                isPaused = true
            } else {
                queuePlayer.resume()
                isPaused = false
            }
        case .avSpeech:
            if avSpeechPaused {
                speechSynth.continueSpeaking()
                avSpeechPaused = false
                isPaused = false
            } else if speechSynth.isSpeaking {
                speechSynth.pauseSpeaking(at: .word)
                avSpeechPaused = true
                isPaused = true
            }
        case .none:
            break
        }
    }

    func rewindFifteenSeconds() {
        switch engine {
        case .queue:
            queuePlayer.seekBackward(seconds: 15)
        case .avSpeech:
            speechSynth.stopSpeaking(at: .immediate)
            avSpeechPaused = false
            let utterance = AVSpeechUtterance(string: avSpeechText)
            utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
            utterance.rate = 0.47
            speechSynth.speak(utterance)
            isPaused = false
        case .none:
            break
        }
    }

    func stopEverything() {
        elevenLabsTask?.cancel()
        elevenLabsTask = nil
        isLoading = false
        queuePlayer.abortSession()
        speechSynth.stopSpeaking(at: .immediate)
        engine = .none
        isSessionActive = false
        isPanelVisible = false
        isLoading = false
        isPaused = false
        activeContentKey = ""
        avSpeechText = ""
        avSpeechPaused = false
    }

    // MARK: - ElevenLabs

    private func runElevenLabs(text: String, classicTaleCacheId: String?) async {
        defer {
            if !Task.isCancelled {
                isLoading = false
            }
        }

        do {
            let urls: [URL]
            let deleteAfter: Bool

            if let taleId = classicTaleCacheId,
               let cached = ClassicTaleNarrationCache.cachedChunkURLs(taleId: taleId),
               !cached.isEmpty {
                urls = cached
                deleteAfter = false
            } else {
                let (voiceId, modelId, voiceSettings) = try await ElevenLabsNarrationService.resolveVoiceModelForNarration(
                    apiKey: Secrets.elevenLabsAPIKey,
                    agentId: Secrets.elevenLabsAgentId,
                    preferredVoiceId: AppConfig.elevenLabsPreferredVoiceId
                )
                let tempURLs = try await ElevenLabsNarrationService.synthesizeToTempFiles(
                    text: text,
                    apiKey: Secrets.elevenLabsAPIKey,
                    voiceId: voiceId,
                    modelId: modelId,
                    voiceSettings: voiceSettings
                )
                try Task.checkCancellation()

                if let taleId = classicTaleCacheId {
                    urls = try ClassicTaleNarrationCache.replaceCache(withTempChunks: tempURLs, taleId: taleId)
                    deleteAfter = false
                } else {
                    urls = tempURLs
                    deleteAfter = true
                }
            }

            try Task.checkCancellation()
            isLoading = false
            isPaused = false

            await activateAudioSession()
            queuePlayer.play(urls: urls, deleteSourceFilesAfterPlayback: deleteAfter) { [weak self] in
                Task { @MainActor in
                    self?.handlePlaybackFullyEnded()
                }
            }
        } catch is CancellationError {
            handlePlaybackFullyEnded()
        } catch {
            AppLogger.error("narration.center.elevenlabs", ["error": String(describing: error)])
            handlePlaybackFullyEnded()
        }
    }

    private func activateAudioSession() async {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            AppLogger.error("narration.center.session", ["error": String(describing: error)])
        }
    }

    // MARK: - AVSpeech

    private func startAVSpeech(text: String) {
        avSpeechText = text
        avSpeechPaused = false
        engine = .avSpeech
        isSessionActive = true
        isPanelVisible = true
        isLoading = false
        isPaused = false

        Task {
            await activateAudioSession()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
            utterance.rate = 0.47
            speechSynth.speak(utterance)
        }
    }

    private func handlePlaybackFullyEnded() {
        engine = .none
        isSessionActive = false
        isPanelVisible = false
        isPaused = false
        isLoading = false
        activeContentKey = ""
        elevenLabsTask = nil
    }
}

extension NarrationPlaybackCenter: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.engine == .avSpeech else { return }
            self.handlePlaybackFullyEnded()
        }
    }
}
