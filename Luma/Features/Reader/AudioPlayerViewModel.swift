import Foundation
import AVFoundation
import Combine
import CoreMedia

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var player: AVPlayer?
    private var currentURLString: String?
    private var failureObserverToken: NSObjectProtocol?
    private var endObserverToken: NSObjectProtocol?

    func play(urlString: String) {
        errorMessage = nil
        configurePlaybackSession()

        guard let url = Self.resolvedAudioURL(from: urlString) else {
            errorMessage = "Geçersiz ses bağlantısı."
            AppLogger.error("audio.play.resolve_failed", AppLogger.narrationURLSummaryFields(urlString))
            return
        }

        AppLogger.info("audio.play.started", AppLogger.narrationURLSummaryFields(urlString))

        isLoading = true

        if currentURLString != urlString {
            detachPlaybackFailureObserver()
            player = AVPlayer(url: url)
            currentURLString = urlString
            attachPlaybackFailureObserver()
        }

        player?.play()
        isPlaying = true
        isLoading = false
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Geçerli konumdan en fazla `seconds` kadar geri sarar (baştan önce durur).
    func skipBackward(seconds: Double) {
        guard let player else { return }
        let current = player.currentTime()
        let delta = CMTime(seconds: seconds, preferredTimescale: current.timescale == 0 ? 600 : current.timescale)
        let target = CMTimeSubtract(current, delta)
        let clamped = CMTimeMaximum(target, .zero)
        player.seek(to: clamped)
    }

    func resume(urlString: String) {
        errorMessage = nil
        configurePlaybackSession()

        guard Self.resolvedAudioURL(from: urlString) != nil else {
            errorMessage = "Geçersiz ses bağlantısı."
            AppLogger.error("audio.resume.resolve_failed", AppLogger.narrationURLSummaryFields(urlString))
            return
        }

        if currentURLString != urlString || player == nil {
            play(urlString: urlString)
            return
        }
        player?.play()
        isPlaying = true
        isLoading = false
    }

    func stop() {
        detachPlaybackFailureObserver()
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
    }

    func toggle(urlString: String) {
        if currentURLString == urlString, isPlaying {
            pause()
            return
        }
        play(urlString: urlString)
    }

    func togglePlayPause(urlString: String) {
        toggle(urlString: urlString)
    }

    func cleanup() {
        AppLogger.debug("audio.cleanup", [:])
        detachPlaybackFailureObserver()
        player?.pause()
        player = nil
        currentURLString = nil
        isPlaying = false
        isLoading = false
    }

    private func configurePlaybackSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            AppLogger.error("audio.session.activate_failed", ["error": String(describing: error)])
        }
    }

    private func attachPlaybackFailureObserver() {
        detachPlaybackFailureObserver()
        guard let item = player?.currentItem else { return }
        // Ses bittiğinde UI "çalıyor" durumunda kalmasın; başa sarılır, tekrar oynat çalışır.
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.isLoading = false
                self.player?.seek(to: .zero)
            }
        }
        failureObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.errorMessage = "Ses dosyası çalınamadı. Bağlantını kontrol et."
                AppLogger.error("audio.playback.item_failed", AppLogger.narrationURLSummaryFields(self.currentURLString))
                self.isPlaying = false
                self.isLoading = false
            }
        }
    }

    private func detachPlaybackFailureObserver() {
        if let token = failureObserverToken {
            NotificationCenter.default.removeObserver(token)
            failureObserverToken = nil
        }
        if let token = endObserverToken {
            NotificationCenter.default.removeObserver(token)
            endObserverToken = nil
        }
    }

    /// Mutlak veya sunucuya göre göreli (`/uploads/...`) ses adresi.
    private static func resolvedAudioURL(from urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let absolute = URL(string: trimmed), absolute.scheme != nil {
            return absolute
        }

        return URL(string: trimmed, relativeTo: AppConfig.backendBaseURL)?.absoluteURL
    }
}
