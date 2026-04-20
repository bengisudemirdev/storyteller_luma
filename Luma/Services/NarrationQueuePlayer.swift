import AVFoundation

/// ElevenLabs’ten gelen çok parçalı MP3’leri oynatır; duraklat, sürdür, geri sar.
@MainActor
final class NarrationQueuePlayer {
    private var queuePlayer: AVQueuePlayer?
    private var endObserver: NSObjectProtocol?
    private var pendingDeletion: [URL] = []
    private var deleteSourcesAfterSession: Bool = true
    private var onSessionFinished: (() -> Void)?

    /// Oturum bittiğinde (son parça çalındı veya `stop`) çağrılır.
    func play(
        urls: [URL],
        deleteSourceFilesAfterPlayback: Bool,
        onFinished: @escaping () -> Void
    ) {
        stopCleanupPlayer(deleteFiles: false)
        guard !urls.isEmpty else {
            onFinished()
            return
        }

        onSessionFinished = onFinished
        deleteSourcesAfterSession = deleteSourceFilesAfterPlayback
        if deleteSourceFilesAfterPlayback {
            pendingDeletion = urls
        } else {
            pendingDeletion = []
        }

        let items = urls.map { AVPlayerItem(url: $0) }
        let qp = AVQueuePlayer(items: items)
        qp.actionAtItemEnd = .advance
        queuePlayer = qp

        if let last = items.last {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: last,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.notifyFinishedIfLast()
                }
            }
        }

        qp.play()
    }

    private func notifyFinishedIfLast() {
        guard queuePlayer != nil else { return }
        finishSession()
    }

    private func finishSession() {
        let cb = onSessionFinished
        onSessionFinished = nil
        stopCleanupPlayer(deleteFiles: deleteSourcesAfterSession)
        cb?()
    }

    func pause() {
        queuePlayer?.pause()
    }

    func resume() {
        queuePlayer?.play()
    }

    var isPlaying: Bool {
        (queuePlayer?.rate ?? 0) > 0
    }

    /// Mevcut parçada `seconds` kadar geri sarar.
    func seekBackward(seconds: Double = 15) {
        guard let qp = queuePlayer else { return }
        let cur = qp.currentTime()
        let delta = CMTime(seconds: seconds, preferredTimescale: 600)
        let target = CMTimeSubtract(cur, delta)
        qp.seek(to: max(target, .zero), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Oynatıcıyı durdurur; `deleteFiles` geçici dosyaları siler (önbellek dosyalarına dokunmaz).
    func stopCleanupPlayer(deleteFiles: Bool) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        queuePlayer = nil

        if deleteFiles {
            for url in pendingDeletion {
                try? FileManager.default.removeItem(at: url)
            }
        }
        pendingDeletion = []
    }

    /// Kullanıcı veya sistem durdurduğunda tam oturumu kapatır.
    func abortSession() {
        let shouldDelete = deleteSourcesAfterSession
        onSessionFinished = nil
        stopCleanupPlayer(deleteFiles: shouldDelete)
    }
}
