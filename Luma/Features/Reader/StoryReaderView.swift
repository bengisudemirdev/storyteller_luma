import SwiftUI

struct StoryReaderView: View {
    let child: ChildModel?
    /// Kayıtlı çocuk yokken (yalnızca isimle masal) üst çubukta gösterilecek ad.
    let heroDisplayName: String?
    let storyTitle: String
    let storyContent: String
    let showSaveButton: Bool
    let story: StoryModel?
    let onSave: (() async -> Void)?

    init(
        child: ChildModel?,
        heroDisplayName: String? = nil,
        storyTitle: String,
        storyContent: String,
        showSaveButton: Bool,
        story: StoryModel?,
        onSave: (() async -> Void)?
    ) {
        self.child = child
        self.heroDisplayName = heroDisplayName
        self.storyTitle = storyTitle
        self.storyContent = storyContent
        self.showSaveButton = showSaveButton
        self.story = story
        self.onSave = onSave
    }

    @State private var currentPage = 0
    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var storyAudioURLState: String?
    @State private var narrationErrorMessage: String?
    @State private var showCreditPaywall = false
    @State private var showFloatingAudioPanel = false
    @AppStorage("story_reader_audio_panel_dx") private var audioPanelStoredDX: Double = 0
    @AppStorage("story_reader_audio_panel_dy") private var audioPanelStoredDY: Double = 0
    @GestureState private var audioPanelDragTranslation: CGSize = .zero
    @StateObject private var audioPlayer = AudioPlayerViewModel()
    @ObservedObject private var entitlements = EntitlementStore.shared
    @EnvironmentObject private var appUIState: AppUIState
    @Environment(\.dismiss) var dismiss

    /// Sayfalar: her sayfa paragraf listesidir. Gerçek ekran boyutu ölçülünce (`repaginate`) yeniden hesaplanır.
    @State private var pages: [[String]] = []
    @State private var lastPaginatedSize: CGSize = .zero

    private var displayPages: [[String]] {
        pages.isEmpty ? StoryReadingPagination.fallbackPages(from: storyContent) : pages
    }

    private var pageCount: Int {
        max(displayPages.count, 1)
    }

    /// Kart dış boşlukları (`pageCardView`) ve kart iç boşluğu; sayfalama bunları düşerek gerçek metin alanını bulur.
    private enum ReaderMetrics {
        static let cardTopInset: CGFloat = 10
        static let cardBottomInset: CGFloat = 12
        static let cardInnerPadding: CGFloat = 22
        static let accentBarHeight: CGFloat = 5
        static let titleBlockSpacing: CGFloat = 10
        static let cardContentSpacing: CGFloat = 16
    }

    private func repaginate(for size: CGSize) {
        guard size.width > 1, size.height > 1, size != lastPaginatedSize else { return }
        lastPaginatedSize = size
        let outerWidth = min(size.width - StoryReadingChrome.horizontalPadding * 2, StoryReadingChrome.cardMaxOuterWidth)
        let textWidth = outerWidth - ReaderMetrics.cardInnerPadding * 2
        let cardHeight = size.height - ReaderMetrics.cardTopInset - ReaderMetrics.cardBottomInset
        let innerHeight = cardHeight - ReaderMetrics.cardInnerPadding * 2
        let titleBlock = ReaderMetrics.accentBarHeight + ReaderMetrics.titleBlockSpacing
            + StoryTextMetrics.titleHeight(storyTitle, width: textWidth) + ReaderMetrics.cardContentSpacing
        pages = StoryReadingPagination.pages(
            from: storyContent,
            textWidth: textWidth,
            firstPageHeight: innerHeight - titleBlock,
            otherPageHeight: innerHeight
        )
        currentPage = min(currentPage, max(pages.count - 1, 0))
    }

    private var hasPlayableStoryAudioURL: Bool {
        guard let s = storyAudioURLState?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return false }
        return true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                StoryReadingWarmBackground()

                VStack(spacing: 0) {
                    storyReaderHeader

                    GeometryReader { proxy in
                        TabView(selection: $currentPage) {
                            ForEach(Array(displayPages.enumerated()), id: \.offset) { index, paragraphs in
                                ScrollView(showsIndicators: false) {
                                    StoryReadingTextCard(
                                        minHeight: proxy.size.height - ReaderMetrics.cardTopInset - ReaderMetrics.cardBottomInset
                                    ) {
                                        VStack(alignment: .leading, spacing: ReaderMetrics.cardContentSpacing) {
                                            if index == 0 {
                                                VStack(alignment: .leading, spacing: ReaderMetrics.titleBlockSpacing) {
                                                    Capsule()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [
                                                                    HomeDashboardPalette.accentOrange,
                                                                    HomeDashboardPalette.accentOrangeSoft
                                                                ],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                        .frame(width: 44, height: ReaderMetrics.accentBarHeight)

                                                    Text(storyTitle)
                                                        .font(.system(size: StoryReadingChrome.titleSize, weight: .bold, design: .serif))
                                                        .foregroundStyle(HomeDashboardPalette.ink)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                }
                                            }

                                            StoryPageBody(paragraphs: paragraphs)
                                        }
                                    }
                                    .frame(maxWidth: StoryReadingChrome.cardMaxOuterWidth)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, StoryReadingChrome.horizontalPadding)
                                    .padding(.top, ReaderMetrics.cardTopInset)
                                    .padding(.bottom, ReaderMetrics.cardBottomInset)
                                }
                                .scrollClipDisabled()
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .onAppear { repaginate(for: proxy.size) }
                        .onChange(of: proxy.size) { _, newSize in repaginate(for: newSize) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    StoryReadingPageControls(currentPage: $currentPage, pageCount: pageCount)
                }
            }

            if showFloatingAudioPanel {
                savedStoryFloatingAudioPanel
                    .padding(.horizontal, HomeDashboardMetrics.mainFloatingChromeHorizontalInset)
                    .padding(.bottom, 10)
                    .offset(audioPanelDisplayedOffset)
                    .gesture(audioPanelDragGesture)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showFloatingAudioPanel)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appUIState.isTabBarVisible = false
            currentPage = min(currentPage, max(pageCount - 1, 0))
            storyAudioURLState = story?.audioUrl ?? story?.audio_url
            audioPlayer.nowPlayingTitle = storyTitle
        }
        .onDisappear {
            appUIState.isTabBarVisible = true
            audioPlayer.stop()
            audioPlayer.cleanup()
            showFloatingAudioPanel = false
        }
        .onChange(of: storyContent) { _, _ in
            lastPaginatedSize = .zero
            pages = []
        }
        .alert("Masalı silmek istiyor musun?", isPresented: $showDeleteAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task { await deleteStoryIfNeeded() }
            }
        } message: {
            Text("Bu işlem, bu masalı kayıtlı masallarından kalıcı olarak silecek.")
        }
        .sheet(isPresented: $showCreditPaywall) {
            if !PortfolioAccessMode.isEnabled {
                PaywallView(
                    source: .insufficientCredits(required: CreditCost.narration),
                    onPurchaseCompleted: {
                        Task {
                            await EntitlementStore.shared.refreshFromBackend()
                            await SubscriptionManager.shared.refreshPlanFromServer()
                            if !hasPlayableStoryAudioURL {
                                await narrateStoryAndPlay()
                            }
                        }
                    }
                )
            }
        }
    }

    private var storyReaderHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HomeDashboardPalette.ink)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(HomeDashboardPalette.accentOrange.opacity(0.22))
                    )
                    .overlay(
                        Circle()
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Kapat"))

            Group {
                if let child {
                    HStack(spacing: 10) {
                        AvatarGlyphView(
                            emoji: child.safeAvatarEmoji,
                            size: 28,
                            color: HomeDashboardPalette.nightMid
                        )
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.cardSurface)
                                .shadow(color: HomeDashboardPalette.cardShadow, radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            Circle()
                                .stroke(HomeDashboardPalette.accentOrange.opacity(0.28), lineWidth: 1)
                        )

                        Text(child.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else if let hero = heroDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !hero.isEmpty {
                    HStack(spacing: 10) {
                        AvatarGlyphView(
                            emoji: ChildModel.defaultAvatarEmoji,
                            size: 28,
                            color: HomeDashboardPalette.nightMid
                        )
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.cardSurface)
                                .shadow(color: HomeDashboardPalette.cardShadow, radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            Circle()
                                .stroke(HomeDashboardPalette.accentOrange.opacity(0.28), lineWidth: 1)
                        )

                        Text(hero)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    Text(AppBrand.displayName)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(HomeDashboardPalette.ink.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // `ViewThatFits` + `.fixedSize` dar ekranda kompakt yerleşimi asla seçmiyor, butonlar adı sıkıştırıp taşıyordu.
            // Başka eylemler (sil/sesli) varsa Kaydet yalnızca ikondur; yoksa etiketiyle görünür.
            headerActions(compact: story != nil)
                .layoutPriority(1)
        }
        .padding(.horizontal, StoryReadingChrome.horizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .frame(maxWidth: StoryReadingChrome.cardMaxOuterWidth)
        .frame(maxWidth: .infinity)
        .background(
            HomeDashboardPalette.dashboardCanvas.opacity(0.92)
                .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 6)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HomeDashboardPalette.accentOrange.opacity(0.08))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func headerActions(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if let onSave = onSave {
                Button {
                    Task { await onSave() }
                } label: {
                    HStack(spacing: compact ? 0 : 6) {
                        Image(systemName: "bookmark.fill")
                        if !compact {
                            Text("Masalı Kaydet")
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, compact ? 9 : 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HomeDashboardPalette.accentOrange.opacity(0.14))
                    )
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.45), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if story != nil {
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.red.opacity(0.88))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.08))
                        )
                }
                .disabled(isDeleting)
                .buttonStyle(.plain)

                Button {
                    showFloatingAudioPanel = true
                    Task { await narrateStoryAndPlay() }
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.accentOrange.opacity(0.18))
                        )
                        .overlay(
                            Circle()
                                .stroke(HomeDashboardPalette.accentOrange.opacity(0.42), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Sesli dinle"))
            }
        }
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

    private var audioPanelDisplayedOffset: CGSize {
        let raw = CGSize(
            width: CGFloat(audioPanelStoredDX) + audioPanelDragTranslation.width,
            height: CGFloat(audioPanelStoredDY) + audioPanelDragTranslation.height
        )
        let clamped = Self.clampStoryReaderAudioPanelOffset(dx: Double(raw.width), dy: Double(raw.height))
        return CGSize(width: clamped.0, height: clamped.1)
    }

    private var audioPanelDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .updating($audioPanelDragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                var nextX = audioPanelStoredDX + Double(value.translation.width)
                var nextY = audioPanelStoredDY + Double(value.translation.height)
                let clamped = Self.clampStoryReaderAudioPanelOffset(dx: nextX, dy: nextY)
                audioPanelStoredDX = clamped.0
                audioPanelStoredDY = clamped.1
            }
    }

    private static func clampStoryReaderAudioPanelOffset(dx: Double, dy: Double) -> (Double, Double) {
        let maxAbsX: Double = 150
        let minY: Double = -420
        let maxY: Double = 80
        let x = min(max(dx, -maxAbsX), maxAbsX)
        let y = min(max(dy, minY), maxY)
        return (x, y)
    }

    private var savedStoryFloatingAudioPanel: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(HomeDashboardPalette.muted.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 2)
                .accessibilityLabel(String(localized: "Paneli sürükleyerek taşı"))

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(HomeDashboardPalette.accentOrange.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(storyTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .lineLimit(1)
                    if audioPlayer.isLoading {
                        Text("Hazırlanıyor…")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    } else if let err = audioPlayer.errorMessage, !err.isEmpty {
                        Text(err)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.88))
                            .lineLimit(2)
                    } else if let narrationErrorMessage, !narrationErrorMessage.isEmpty {
                        Text(narrationErrorMessage)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.88))
                            .lineLimit(2)
                    } else if hasPlayableStoryAudioURL {
                        Text(audioPlayer.isPlaying ? "Çalıyor" : "Duraklatıldı")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    } else {
                        Text("Ses kaydı bekleniyor")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showFloatingAudioPanel = false
                    narrationErrorMessage = nil
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.muted.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Kapat"))
            }

            HStack(spacing: 18) {
                Button {
                    audioPlayer.skipBackward(seconds: 15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.ink)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayer.isLoading || !hasPlayableStoryAudioURL)

                Button {
                    if let url = storyAudioURLState?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty {
                        audioPlayer.toggle(urlString: url)
                        narrationErrorMessage = nil
                    }
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayer.isLoading || !hasPlayableStoryAudioURL)

                Button {
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayer.isLoading)
            }
            .frame(maxWidth: .infinity)

            if narrationErrorMessage != nil && !entitlements.hasPremiumAccess && !PortfolioAccessMode.isEnabled {
                Button("Planları gör") {
                    showCreditPaywall = true
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(HomeDashboardPalette.dashboardCanvas)
                .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
        )
    }

    private func narrateStoryAndPlay() async {
        AppLogger.info("narration.saved_story.flow_started", [
            "hasPersistedStoryId": story?.id != nil ? "true" : "false",
            "hasCachedAudioUrl": (storyAudioURLState?.isEmpty == false) ? "true" : "false"
        ])
        guard let storyId = story?.id else {
            AppLogger.warning("narration.saved_story.skipped_no_story_id", [
                "reason": "Masal henüz kaydedilmemiş veya id yok; seslendirme API çağrısı yapılamaz."
            ])
            return
        }
        if let existing = storyAudioURLState, !existing.isEmpty {
            AppLogger.info("narration.saved_story.play_existing_url", [
                "storyId": storyId.uuidString
            ].merging(AppLogger.narrationURLSummaryFields(existing)) { _, new in new })
            await MainActor.run {
                audioPlayer.play(urlString: existing)
            }
            return
        }

        // Yerel masal nesnesi eski olabilir (ses başka bir cihazda ya da liste yenilenmeden önce üretilmiş olabilir).
        // Sunucuda bu masal için ses zaten kayıtlıysa hak kontrolüne takılmadan doğrudan çal: tekrar dinlemek hak düşürmez.
        if let saved = try? await StoryAPIService.fetchStory(id: storyId),
           let savedURL = (saved.audioUrl ?? saved.audio_url)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !savedURL.isEmpty {
            AppLogger.info("narration.saved_story.play_server_saved_audio", [
                "storyId": storyId.uuidString
            ].merging(AppLogger.narrationURLSummaryFields(savedURL)) { _, new in new })
            await MainActor.run {
                storyAudioURLState = savedURL
                audioPlayer.isLoading = false
                audioPlayer.play(urlString: savedURL)
            }
            return
        }

        await EntitlementStore.shared.refreshFromBackend()
        await SubscriptionManager.shared.refreshPlanFromServer()
        let ent = EntitlementStore.shared
        guard ent.canNarrateStory else {
            AppLogger.warning("narration.saved_story.blocked_entitlements", [
                "storyId": storyId.uuidString,
                "voiceRemainingThisMonth": "\(ent.voiceRemainingThisMonth ?? 0)",
                "extraVoiceCredits": "\(ent.extraVoiceCredits ?? 0)",
                "hasPremiumAccess": ent.hasPremiumAccess ? "true" : "false"
            ])
            await MainActor.run {
                narrationErrorMessage = ent.hasPremiumAccess
                    ? "Bu ay için sesli masal hakkın doldu."
                    : "Seslendirme için uygun bir plan veya hak gerekiyor."
                audioPlayer.isLoading = false
                if !ent.hasPremiumAccess && !PortfolioAccessMode.isEnabled {
                    showCreditPaywall = true
                }
            }
            return
        }

        await MainActor.run {
            narrationErrorMessage = nil
            audioPlayer.errorMessage = nil
            audioPlayer.isLoading = true
        }

        AppLogger.info("narration.saved_story.api_call_pending", ["storyId": storyId.uuidString])

        do {
            let response = try await StoryService.narrateStory(id: storyId)
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
            AppLogger.info("narration.saved_story.api_success_playing", [
                "storyId": storyId.uuidString
            ].merging(AppLogger.narrationURLSummaryFields(response.audioUrl)) { _, new in new })
            await MainActor.run {
                storyAudioURLState = response.audioUrl
                audioPlayer.isLoading = false
                audioPlayer.play(urlString: response.audioUrl)
            }
        } catch let error as APIClientError {
            var fields: [String: String] = [
                "storyId": storyId.uuidString,
                "errorType": "APIClientError",
                "insufficientCredits": error.isInsufficientCredits ? "true" : "false"
            ]
            if case .server(let code, let message) = error {
                fields["serverCode"] = code
                fields["serverMessageSnippet"] = String(message.prefix(120))
            } else if case .networkFailure(let message) = error {
                fields["networkMessageSnippet"] = String(message.prefix(120))
            }
            AppLogger.error("narration.saved_story.api_failed", fields)
            await MainActor.run {
                audioPlayer.isLoading = false
                if error.isInsufficientCredits || error.serverErrorCode == "VOICE_LIMIT_REACHED" {
                    narrationErrorMessage = PortfolioAccessMode.isEnabled
                        ? "Seslendirme şu an başlatılamadı. Lütfen biraz sonra tekrar dene."
                        : EntitlementStore.shared.hasPremiumAccess
                        ? "Seslendirme şu an başlatılamadı. Biraz sonra tekrar dene."
                        : "Seslendirme için uygun bir plan veya hak gerekiyor."
                    if !EntitlementStore.shared.hasPremiumAccess && !PortfolioAccessMode.isEnabled {
                        showCreditPaywall = true
                    }
                } else if case .unauthorized = error {
                    narrationErrorMessage = "Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap."
                } else {
                    narrationErrorMessage = "Masal seslendirilirken bir sorun oluştu. Lütfen tekrar dene."
                }
            }
        } catch {
            AppLogger.error("narration.saved_story.unexpected_error", [
                "storyId": storyId.uuidString,
                "errorType": String(describing: type(of: error))
            ])
            await MainActor.run {
                audioPlayer.isLoading = false
                narrationErrorMessage = "Masal seslendirilirken bir sorun oluştu. Lütfen tekrar dene."
            }
        }
    }
}
