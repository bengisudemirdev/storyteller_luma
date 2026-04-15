import SwiftUI
import AVFoundation
import AVKit

struct StoryReaderView: View {
    let child: ChildModel?
    let storyTitle: String
    let storyContent: String
    let showSaveButton: Bool
    let story: StoryModel?
    let onSave: (() async -> Void)?

    @State private var currentPage = 0
    @State private var isDeleting = false
    @State private var isSaving = false
    @State private var showDeleteAlert = false
    @State private var isSpeaking = false
    @State private var isElevenLabsLoading = false
    @State private var elevenLabsErrorMessage: String?
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var backendAudioPlayer: AVPlayer?
    @State private var backendPlaybackObserverToken: Any?
    @State private var elevenLabsPlayer = ElevenLabsSequentialPlayer()
    @State private var elevenLabsTask: Task<Void, Never>?
    @State private var backendNarrationPrepareTask: Task<Void, Never>?
    @State private var shouldAutoplayWhenBackendReady = false
    @State private var magicLoaderAnimate = false
    @EnvironmentObject private var appUIState: AppUIState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            readerBackground
                .ignoresSafeArea()
            VStack(spacing: 14) {
                headerBar
                storyMetaCard
                pageContainer
                pageControlBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)

            if isElevenLabsLoading {
                magicNarrationLoaderOverlay
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appUIState.isTabBarVisible = false
            prewarmNarrationIfNeeded()
        }
        .onDisappear { 
            appUIState.isTabBarVisible = true
            stopSpeaking()
            backendNarrationPrepareTask?.cancel()
            backendNarrationPrepareTask = nil
        }
        .animation(.easeInOut(duration: 0.25), value: isElevenLabsLoading)
        .alert("Masalı silmek istiyor musun?", isPresented: $showDeleteAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task { await deleteStoryIfNeeded() }
            }
        } message: {
            Text("Bu işlem, bu masalı kayıtlı masallarından kalıcı olarak silecek.")
        }
        .alert("Seslendirme Uyarısı", isPresented: Binding(
            get: { elevenLabsErrorMessage != nil },
            set: { if !$0 { elevenLabsErrorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { elevenLabsErrorMessage = nil }
        } message: {
            Text(elevenLabsErrorMessage ?? "Seslendirme sırasında bir sorun oluştu.")
        }
    }

    private var readerBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: "F8F1E6"),
                Color(hex: "F4EBDD"),
                Color(hex: "F0E5D6")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HomeDashboardPalette.ink)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color(hex: "F6EEDF").opacity(0.98))
                    )
                    .overlay(
                        Circle()
                            .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
                    )
                    .shadow(color: HomeDashboardPalette.cardShadow.opacity(0.55), radius: 6, x: 0, y: 2)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(AppBrand.displayName)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text(isClassicMode ? "Klasik Masal" : "Masal Okuyucu")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            Spacer()
            HStack(spacing: 8) {
                if isNarrationActive {
                    actionChip(
                        icon: "play.fill",
                        text: narrationPrimaryButtonTitle,
                        tint: HomeDashboardPalette.nightMid
                    ) {
                        startNarration()
                    }
                    .disabled(isElevenLabsLoading)
                    .opacity(isElevenLabsLoading ? 0.6 : 1)

                    actionChip(
                        icon: "stop.fill",
                        text: "Durdur",
                        tint: .red.opacity(0.85)
                    ) {
                        pauseNarration()
                    }
                } else {
                    actionChip(
                        icon: "speaker.wave.2.fill",
                        text: "Seslendir",
                        tint: HomeDashboardPalette.nightMid
                    ) {
                        startNarration()
                    }
                }

                if showSaveButton, let onSave = onSave {
                    actionChip(
                        icon: "bookmark.fill",
                        text: isSaving ? "Kaydediliyor" : "Kaydet",
                        tint: HomeDashboardPalette.accentOrange,
                        isLoading: isSaving
                    ) {
                        Task {
                            guard !isSaving else { return }
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }
                }

                if story != nil {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "F7EFE1").opacity(0.98))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red.opacity(0.18), lineWidth: 1))
                            .shadow(color: HomeDashboardPalette.cardShadow.opacity(0.45), radius: 5, x: 0, y: 2)
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var narrationLoadingBanner: some View {
        if isElevenLabsLoading {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.85)
                    .tint(HomeDashboardPalette.nightMid)
                Text("Seslendirme hazırlanıyor...")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: "EFE5D5").opacity(0.95))
            )
        }
    }

    private var storyMetaCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.24))
                    .frame(width: 44, height: 44)
                AvatarGlyphView(
                    emoji: child?.safeAvatarEmoji ?? "📖",
                    size: 22,
                    color: HomeDashboardPalette.nightMid
                )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(storyTitle)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                    .lineLimit(2)
                Text(isClassicMode ? "Klasik anlatım" : "Kişiselleştirilmiş hikaye")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            Spacer(minLength: 8)
            Text("\(storyPages.count) sayfa")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(HomeDashboardPalette.accentOrange.opacity(0.14))
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "F3E9D8").opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
        )
        .shadow(color: HomeDashboardPalette.cardShadow.opacity(0.6), radius: 8, x: 0, y: 3)
    }

    private var pageContainer: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(storyPages.enumerated()), id: \.offset) { index, pageText in
                VStack(alignment: .leading, spacing: 22) {
                    Text(pageText)
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .lineSpacing(8)
                        .foregroundStyle(HomeDashboardPalette.ink.opacity(0.94))
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .padding(.bottom, 20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: "F7EFDF").opacity(0.98))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
                )
                .shadow(color: HomeDashboardPalette.cardShadow.opacity(0.62), radius: 9, x: 0, y: 4)
                .padding(.vertical, 2)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var pageControlBar: some View {
        VStack(spacing: 10) {
            if !isElevenLabsLoading {
                narrationLoadingBanner
            }
            HStack(spacing: 8) {
                ForEach(Array(storyPages.indices), id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.muted.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)
                }
            }

            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentPage = max(0, currentPage - 1)
                    }
                } label: {
                    Label("Önceki", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(HomeDashboardPalette.creamDeep)
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .clipShape(Capsule())
                }
                .disabled(currentPage == 0)
                .opacity(currentPage == 0 ? 0.4 : 1)

                Spacer()

                Text("Sayfa \(currentPage + 1) / \(max(storyPages.count, 1))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentPage = min(storyPages.count - 1, currentPage + 1)
                    }
                } label: {
                    Label("Sonraki", systemImage: "chevron.right")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(HomeDashboardPalette.accentOrange.opacity(0.18))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .clipShape(Capsule())
                }
                .disabled(currentPage >= storyPages.count - 1)
                .opacity(currentPage >= storyPages.count - 1 ? 0.4 : 1)
            }
        }
        .padding(.horizontal, 2)
    }

    private var magicNarrationLoaderOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    HomeDashboardPalette.accentOrange.opacity(0.15),
                                    HomeDashboardPalette.accentOrange.opacity(0.85),
                                    HomeDashboardPalette.nightMid.opacity(0.9),
                                    HomeDashboardPalette.accentOrange.opacity(0.15)
                                ],
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(magicLoaderAnimate ? 360 : 0))
                        .animation(.linear(duration: 2.2).repeatForever(autoreverses: false), value: magicLoaderAnimate)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    HomeDashboardPalette.accentOrangeSoft.opacity(0.6),
                                    HomeDashboardPalette.accentOrange.opacity(0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 48
                            )
                        )
                        .frame(width: 106, height: 106)
                        .scaleEffect(magicLoaderAnimate ? 1.08 : 0.92)
                        .opacity(magicLoaderAnimate ? 1 : 0.72)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.nightMid)
                        .rotationEffect(.degrees(magicLoaderAnimate ? 7 : -5))
                }

                Text("Seslendirme büyüsü hazırlanıyor...")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(HomeDashboardPalette.accentOrange)
                            .frame(width: 8, height: 8)
                            .scaleEffect(magicLoaderAnimate ? 1.0 : 0.55)
                            .opacity(magicLoaderAnimate ? 1 : 0.35)
                            .animation(
                                .easeInOut(duration: 0.75)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.14),
                                value: magicLoaderAnimate
                            )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: "F6EEDF").opacity(0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
            .onAppear {
                magicLoaderAnimate = true
            }
            .onDisappear {
                magicLoaderAnimate = false
            }
        }
        .allowsHitTesting(false)
    }

    private var isClassicMode: Bool {
        story == nil && onSave == nil
    }

    private var isNarrationActive: Bool {
        isSpeaking || isElevenLabsLoading || backendAudioPlayer != nil
    }

    private var narrationPrimaryButtonTitle: String {
        if isSpeaking { return "Çalıyor" }
        if let player = backendAudioPlayer {
            if isPlayerPaused(player) { return "Devam Et" }
        }
        return "Başlat"
    }

    private func actionChip(
        icon: String,
        text: String,
        tint: Color,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.78)
                        .tint(tint)
                } else {
                    Image(systemName: icon)
                }
                Text(text)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(hex: "F7EFE1").opacity(0.98))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: HomeDashboardPalette.cardShadow.opacity(0.4), radius: 4, x: 0, y: 2)
        }
    }

    private var storyPages: [String] {
        let rawBlocks = storyContent
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawBlocks.isEmpty else { return [storyContent.trimmingCharacters(in: .whitespacesAndNewlines)] }

        var pages: [String] = []
        var current = ""
        // Kart içinde kaydırma yok: sayfa başına metin daha küçük tutulur.
        let targetLength = 760

        for block in rawBlocks {
            if current.isEmpty {
                current = block
            } else if (current.count + block.count + 2) < targetLength {
                current += "\n\n" + block
            } else {
                pages.append(current)
                current = block
            }
        }
        if !current.isEmpty {
            pages.append(current)
        }
        return pages.isEmpty ? [storyContent] : pages
    }

    private func deleteStoryIfNeeded() async {
        guard let storyId = story?.id else { return }
        isDeleting = true
        do {
            try await StoryService.deleteStory(id: storyId)
            dismiss()
        } catch {
            AppLogger.error("stories.delete.failed", [
                "storyId": storyId.uuidString,
                "error": String(describing: type(of: error))
            ])
        }
        isDeleting = false
    }

    // MARK: - Speech

    private func startNarration() {
        guard !storyContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        shouldAutoplayWhenBackendReady = true

        if let player = backendAudioPlayer {
            if isPlayerAtEnd(player) {
                player.seek(to: .zero)
            }
            player.play()
            attachBackendPlaybackObserverIfNeeded(player)
            isSpeaking = true
            return
        }

        stopSpeaking(resetBackendPlayer: false)
        if let storyId = story?.id {
            if backendNarrationPrepareTask != nil || isElevenLabsLoading {
                return
            }
            elevenLabsTask = Task { @MainActor in
                await startBackendNarration(storyId: storyId)
            }
        } else if AppConfig.isElevenLabsNarrationConfigured {
            elevenLabsTask = Task { @MainActor in
                await startElevenLabsNarration()
            }
        } else {
            startSpeaking()
        }
    }

    private func startSpeaking() {
        stopSpeaking()
        speakWithSystemTTS()
    }

    private func speakWithSystemTTS() {
        let utterance = AVSpeechUtterance(string: storyContent)
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        utterance.rate = 0.47
        utterance.pitchMultiplier = 1.0
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }

    @MainActor
    private func startBackendNarration(
        storyId: UUID,
        showErrorsInUI: Bool = true,
        showLoadingInUI: Bool = true
    ) async {
        if showLoadingInUI {
            isElevenLabsLoading = true
        }
        isSpeaking = false
        do {
            let audioURLString = try await StoryService.generateStoryAudioURL(id: storyId)
            guard let url = URL(string: audioURLString) else {
                throw APIClientError.invalidURL
            }
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try session.setActive(true, options: [])
            } catch {
                AppLogger.error("audio.session.failed", ["error": String(describing: error)])
            }

            detachBackendPlaybackObserver()
            let player = AVPlayer(url: url)
            backendAudioPlayer = player
            attachBackendPlaybackObserverIfNeeded(player)
            if showLoadingInUI {
                isElevenLabsLoading = false
            }
            if shouldAutoplayWhenBackendReady {
                isSpeaking = true
                player.play()
            }
        } catch {
            AppLogger.error("stories.audio.failed", [
                "storyId": storyId.uuidString,
                "error": String(describing: error)
            ])
            if showErrorsInUI {
                elevenLabsErrorMessage = "Seslendirme başlatılamadı: \(error.userFacingTurkishMessage)"
            }
            isSpeaking = false
            if showLoadingInUI {
                isElevenLabsLoading = false
            }
        }
    }

    @MainActor
    private func startElevenLabsNarration() async {
        isElevenLabsLoading = true
        isSpeaking = false
        do {
            let apiKey = Secrets.elevenLabsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            let agentId = Secrets.elevenLabsAgentId.trimmingCharacters(in: .whitespacesAndNewlines)
            let preferredVoiceId = AppConfig.elevenLabsPreferredVoiceId
            let resolvedVoiceId: String
            let modelId: String
            let voiceSettings: ElevenLabsAgentResponse.VoiceSettings?

            if let preferredVoiceId {
                resolvedVoiceId = preferredVoiceId
                modelId = "eleven_multilingual_v2"
                voiceSettings = nil
            } else if !agentId.isEmpty {
                let (agentVoiceId, resolvedModelId, resolvedSettings) = try await ElevenLabsNarrationService.resolveVoiceAndModel(
                    apiKey: apiKey,
                    agentId: agentId
                )
                resolvedVoiceId = agentVoiceId
                modelId = resolvedModelId
                voiceSettings = resolvedSettings
            } else {
                throw ElevenLabsNarrationError.missingVoiceId
            }

            AppLogger.info("elevenlabs.voice.selected", [
                "source": preferredVoiceId == nil ? "agent" : "voice_override",
                "voiceIdSuffix": String(resolvedVoiceId.suffix(6)),
                "modelId": modelId
            ])
            let urls = try await ElevenLabsNarrationService.synthesizeToTempFiles(
                text: storyContent,
                apiKey: apiKey,
                voiceId: resolvedVoiceId,
                modelId: modelId,
                voiceSettings: voiceSettings
            )
            try Task.checkCancellation()
            isElevenLabsLoading = false
            isSpeaking = true
            try await elevenLabsPlayer.play(urls: urls)
        } catch is CancellationError {
            // kullanıcı durdurdu
            isElevenLabsLoading = false
        } catch {
            AppLogger.error("elevenlabs.narration.failed", ["error": String(describing: error)])
            elevenLabsErrorMessage = "ElevenLabs sesi başlatılamadı: \(error.userFacingTurkishMessage)"
            isElevenLabsLoading = false
        }
        isSpeaking = false
        elevenLabsPlayer.stop()
    }

    private func pauseNarration() {
        shouldAutoplayWhenBackendReady = false
        backendAudioPlayer?.pause()
        elevenLabsPlayer.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isElevenLabsLoading = false
    }

    private func stopSpeaking(resetBackendPlayer: Bool = true) {
        shouldAutoplayWhenBackendReady = false
        elevenLabsTask?.cancel()
        elevenLabsTask = nil
        backendNarrationPrepareTask?.cancel()
        backendNarrationPrepareTask = nil
        backendAudioPlayer?.pause()
        if resetBackendPlayer {
            detachBackendPlaybackObserver()
            backendAudioPlayer = nil
        }
        elevenLabsPlayer.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isElevenLabsLoading = false
    }

    private func prewarmNarrationIfNeeded() {
        guard let storyId = story?.id else { return }
        guard backendAudioPlayer == nil else { return }
        guard backendNarrationPrepareTask == nil else { return }

        backendNarrationPrepareTask = Task { @MainActor in
            await startBackendNarration(
                storyId: storyId,
                showErrorsInUI: false,
                showLoadingInUI: false
            )
            backendNarrationPrepareTask = nil
        }
    }

    private func isPlayerPaused(_ player: AVPlayer) -> Bool {
        player.rate == 0
    }

    private func isPlayerAtEnd(_ player: AVPlayer) -> Bool {
        guard let item = player.currentItem else { return false }
        let duration = item.duration.seconds
        let current = item.currentTime().seconds
        guard duration.isFinite, current.isFinite, duration > 0 else { return false }
        return current >= duration - 0.3
    }

    private func attachBackendPlaybackObserverIfNeeded(_ player: AVPlayer) {
        guard backendPlaybackObserverToken == nil else { return }
        let interval = CMTime(seconds: 0.35, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        backendPlaybackObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let current = time.seconds
            guard current.isFinite, let item = player.currentItem else { return }
            let duration = item.duration.seconds
            guard duration.isFinite, duration > 0 else { return }

            let progress = max(0, min(1, current / duration))
            let nextPage = pageIndex(forAudioProgress: progress)
            if nextPage != currentPage {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentPage = nextPage
                }
            }

            if current >= duration - 0.08 {
                isSpeaking = false
            }
        }
    }

    private func detachBackendPlaybackObserver() {
        guard let token = backendPlaybackObserverToken, let player = backendAudioPlayer else {
            backendPlaybackObserverToken = nil
            return
        }
        player.removeTimeObserver(token)
        backendPlaybackObserverToken = nil
    }

    private func pageIndex(forAudioProgress progress: Double) -> Int {
        guard storyPages.count > 1 else { return 0 }
        let lengths = storyPages.map(\.count)
        let total = max(lengths.reduce(0, +), 1)
        var cumulative = 0
        for (index, length) in lengths.enumerated() {
            cumulative += length
            let boundary = Double(cumulative) / Double(total)
            if progress <= boundary || index == lengths.count - 1 {
                return index
            }
        }
        return max(0, storyPages.count - 1)
    }
}
