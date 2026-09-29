import Foundation
import AVFoundation
import Combine
import CoreMedia
import MediaPlayer

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Kilit ekranı / Denetim Merkezi'nde gösterilen başlık.
    var nowPlayingTitle: String = "Olia Masalı"

    private static let skipInterval: Double = 15

    private var player: AVPlayer?
    private var currentURLString: String?
    private var failureObserverToken: NSObjectProtocol?
    private var endObserverToken: NSObjectProtocol?
    private var interruptionObserverToken: NSObjectProtocol?
    private var routeChangeObserverToken: NSObjectProtocol?
    private var timeObserverToken: Any?
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []
    private var shouldResumeAfterInterruption = false

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
            detachPlayerObservers()
            player = AVPlayer(url: url)
            currentURLString = urlString
            attachPlayerObservers()
        }

        registerRemoteCommands()
        player?.play()
        isPlaying = true
        isLoading = false
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    /// Geçerli konumdan en fazla `seconds` kadar geri sarar (baştan önce durur).
    func skipBackward(seconds: Double) {
        seek(by: -seconds)
    }

    func skipForward(seconds: Double) {
        seek(by: seconds)
    }

    private func seek(by delta: Double) {
        guard let player else { return }
        let current = player.currentTime().seconds
        guard current.isFinite else { return }
        var target = max(current + delta, 0)
        if let duration = player.currentItem?.duration.seconds, duration.isFinite {
            target = min(target, duration)
        }
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600)) { [weak self] _ in
            Task { @MainActor in self?.updateNowPlayingInfo() }
        }
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
        registerRemoteCommands()
        player?.play()
        isPlaying = true
        isLoading = false
        updateNowPlayingInfo()
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        clearNowPlaying()
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
        detachPlayerObservers()
        player?.pause()
        player = nil
        currentURLString = nil
        isPlaying = false
        isLoading = false
        clearNowPlaying()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - Session

    private func configurePlaybackSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // UIBackgroundModes=audio + .playback: ekran kilitlenince / uygulama arka plana geçince çalmaya devam eder.
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true, options: [])
        } catch {
            AppLogger.error("audio.session.activate_failed", ["error": String(describing: error)])
        }
    }

    // MARK: - Observers

    private func attachPlayerObservers() {
        detachPlayerObservers()
        guard let player, let item = player.currentItem else { return }
        let center = NotificationCenter.default

        // Ses bittiğinde UI "çalıyor" durumunda kalmasın; başa sarılır, tekrar oynat çalışır.
        endObserverToken = center.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.isLoading = false
                self.player?.seek(to: .zero)
                self.updateNowPlayingInfo()
            }
        }

        failureObserverToken = center.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.errorMessage = "Ses dosyası çalınamadı. Bağlantını kontrol et."
                AppLogger.error("audio.playback.item_failed", AppLogger.narrationURLSummaryFields(self.currentURLString))
                self.isPlaying = false
                self.isLoading = false
                self.updateNowPlayingInfo()
            }
        }

        // Arama / Siri / alarm gibi kesintiler: dur, kesinti bitince (sistem izin verirse) devam et.
        interruptionObserverToken = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            let typeRaw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor in
                guard let self, let typeRaw, let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
                switch type {
                case .began:
                    self.shouldResumeAfterInterruption = self.isPlaying
                    self.player?.pause()
                    self.isPlaying = false
                    self.updateNowPlayingInfo()
                case .ended:
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw ?? 0)
                    if self.shouldResumeAfterInterruption, options.contains(.shouldResume) {
                        self.configurePlaybackSession()
                        self.player?.play()
                        self.isPlaying = true
                        self.updateNowPlayingInfo()
                    }
                    self.shouldResumeAfterInterruption = false
                @unknown default:
                    break
                }
            }
        }

        // Kulaklık çıkarılınca sesi hoparlörden aniden vermek yerine duraklat.
        routeChangeObserverToken = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            let reasonRaw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor in
                guard let self, let reasonRaw,
                      AVAudioSession.RouteChangeReason(rawValue: reasonRaw) == .oldDeviceUnavailable else { return }
                self.pause()
            }
        }

        // Kilit ekranındaki ilerleme çubuğu için saniyelik güncelleme.
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateNowPlayingInfo() }
        }
    }

    private func detachPlayerObservers() {
        let center = NotificationCenter.default
        [failureObserverToken, endObserverToken, interruptionObserverToken, routeChangeObserverToken]
            .compactMap { $0 }
            .forEach { center.removeObserver($0) }
        failureObserverToken = nil
        endObserverToken = nil
        interruptionObserverToken = nil
        routeChangeObserverToken = nil
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    // MARK: - Lock screen / Control Center

    private func registerRemoteCommands() {
        guard remoteCommandTargets.isEmpty else { return }
        let center = MPRemoteCommandCenter.shared()

        func add(_ command: MPRemoteCommand, _ handler: @escaping @MainActor (AudioPlayerViewModel, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
            let target = command.addTarget { [weak self] event in
                guard let self else { return .commandFailed }
                return MainActor.assumeIsolated { handler(self, event) }
            }
            command.isEnabled = true
            remoteCommandTargets.append((command, target))
        }

        add(center.playCommand) { vm, _ in
            vm.player?.play()
            vm.isPlaying = true
            vm.updateNowPlayingInfo()
            return .success
        }
        add(center.pauseCommand) { vm, _ in
            vm.pause()
            return .success
        }
        add(center.togglePlayPauseCommand) { vm, _ in
            if vm.isPlaying { vm.pause() } else {
                vm.player?.play()
                vm.isPlaying = true
                vm.updateNowPlayingInfo()
            }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        add(center.skipForwardCommand) { vm, _ in
            vm.skipForward(seconds: Self.skipInterval)
            return .success
        }
        add(center.skipBackwardCommand) { vm, _ in
            vm.skipBackward(seconds: Self.skipInterval)
            return .success
        }
        add(center.changePlaybackPositionCommand) { vm, event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            vm.player?.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 600)) { _ in
                Task { @MainActor in vm.updateNowPlayingInfo() }
            }
            return .success
        }
    }

    private func unregisterRemoteCommands() {
        for (command, target) in remoteCommandTargets {
            command.removeTarget(target)
        }
        remoteCommandTargets.removeAll()
    }

    private func updateNowPlayingInfo() {
        guard let player, currentURLString != nil else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlayingTitle,
            MPMediaItemPropertyArtist: "Olia",
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        let elapsed = player.currentTime().seconds
        if elapsed.isFinite { info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed }
        if let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        unregisterRemoteCommands()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
