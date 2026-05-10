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
    @State private var showAudioPanel = false
    @StateObject private var audioPlayer = AudioPlayerViewModel()
    @ObservedObject private var entitlements = EntitlementStore.shared
    @EnvironmentObject private var appUIState: AppUIState
    @Environment(\.dismiss) var dismiss

    private var storyPages: [String] {
        StoryReadingPagination.pages(
            from: storyContent,
            firstPageBudget: 700,
            otherPageBudget: 1200
        )
    }

    private var pageCount: Int {
        max(storyPages.count, 1)
    }

    var body: some View {
        ZStack {
            StoryReadingWarmBackground()

            VStack(spacing: 0) {
                storyReaderHeader

                TabView(selection: $currentPage) {
                    ForEach(Array(storyPages.enumerated()), id: \.offset) { index, pageText in
                        ScrollView(showsIndicators: false) {
                            StoryReadingTextCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    if index == 0 {
                                        VStack(alignment: .leading, spacing: 10) {
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
                                                .frame(width: 44, height: 5)

                                            Text(storyTitle)
                                                .font(.system(size: StoryReadingChrome.titleSize, weight: .bold, design: .serif))
                                                .foregroundStyle(HomeDashboardPalette.ink)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    Text(pageText)
                                        .storyReadingBodyStyle()
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .frame(maxWidth: StoryReadingChrome.cardMaxOuterWidth)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, StoryReadingChrome.horizontalPadding)
                            .padding(.top, 10)
                            .padding(.bottom, 32)
                        }
                        .scrollClipDisabled()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                StoryReadingPageControls(currentPage: $currentPage, pageCount: pageCount)
            }

            if showAudioPanel {
                audioPanelOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topTrailing)))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: showAudioPanel)
        .navigationBarHidden(true)
        .onAppear {
            appUIState.isTabBarVisible = false
            currentPage = min(currentPage, max(pageCount - 1, 0))
            storyAudioURLState = story?.audioUrl ?? story?.audio_url
        }
        .onDisappear {
            appUIState.isTabBarVisible = true
            audioPlayer.stop()
            audioPlayer.cleanup()
        }
        .onChange(of: storyPages.count) { _, newCount in
            currentPage = min(currentPage, max(newCount - 1, 0))
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
            PaywallView(
                source: .insufficientCredits(required: CreditCost.narration),
                onPurchaseCompleted: {
                    Task {
                        await EntitlementStore.shared.refreshFromBackend()
                        await SubscriptionManager.shared.refreshPlanFromServer()
                    }
                }
            )
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
                    }
                } else {
                    Text(AppBrand.displayName)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(HomeDashboardPalette.ink.opacity(0.88))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ViewThatFits(in: .horizontal) {
                headerActions(compact: false)
                headerActions(compact: true)
            }
            .fixedSize(horizontal: true, vertical: false)
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
                    showAudioPanel.toggle()
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

    private var audioPanelOverlay: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showAudioPanel = false
                    }

                audioFloatingPanel
                    .frame(width: min(geo.size.width - 24, 300), alignment: .leading)
                    .padding(.top, geo.safeAreaInsets.top + 46)
                    .padding(.trailing, 12)
            }
        }
    }

    private var audioFloatingPanel: some View {
        let trimmedAudioURL = storyAudioURLState?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasAudioURL = !trimmedAudioURL.isEmpty

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("Sesli dinle")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Spacer(minLength: 8)
                Button {
                    showAudioPanel = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Kapat"))
            }

            if let error = narrationErrorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let playErr = audioPlayer.errorMessage {
                Text(playErr)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if audioPlayer.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(HomeDashboardPalette.accentOrange)
                    Text("Masal seslendiriliyor...")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                }
            }

            if hasAudioURL {
                HStack(spacing: 8) {
                    Button {
                        audioPlayer.skipBackward(seconds: 10)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 22, weight: .semibold))
                            Text("10 sn")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "On saniye geri"))

                    Button {
                        narrationErrorMessage = nil
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else {
                            audioPlayer.resume(urlString: trimmedAudioURL)
                        }
                    } label: {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(audioPlayer.isPlaying ? String(localized: "Duraklat") : String(localized: "Oynat"))

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
            } else if !audioPlayer.isLoading {
                Button {
                    Task { await narrateStoryAndPlay() }
                } label: {
                    Text("Masalı seslendir")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AudioActionButtonStyle())
                .disabled(audioPlayer.isLoading)
            }

            if narrationErrorMessage != nil && !entitlements.hasPremiumAccess {
                Button("Planları gör") {
                    showCreditPaywall = true
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.2), lineWidth: 1)
        )
    }

    private func narrateStoryAndPlay() async {
        guard let storyId = story?.id else { return }
        if let existing = storyAudioURLState, !existing.isEmpty {
            audioPlayer.play(urlString: existing)
            return
        }

        await EntitlementStore.shared.refreshFromBackend()
        await SubscriptionManager.shared.refreshPlanFromServer()
        guard EntitlementStore.shared.canNarrateStory else {
            await MainActor.run {
                narrationErrorMessage = EntitlementStore.shared.hasPremiumAccess
                    ? "Bu ay için sesli masal hakkın doldu."
                    : "Seslendirme için uygun bir plan veya hak gerekiyor."
                audioPlayer.isLoading = false
                if !EntitlementStore.shared.hasPremiumAccess {
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

        do {
            let response = try await StoryService.narrateStory(id: storyId)
            await EntitlementStore.shared.refreshFromBackend()
            await SubscriptionManager.shared.refreshPlanFromServer()
            await MainActor.run {
                storyAudioURLState = response.audioUrl
                audioPlayer.isLoading = false
                audioPlayer.play(urlString: response.audioUrl)
            }
        } catch let error as APIClientError {
            await MainActor.run {
                audioPlayer.isLoading = false
                if error.isInsufficientCredits {
                    narrationErrorMessage = EntitlementStore.shared.hasPremiumAccess
                        ? "Seslendirme şu an başlatılamadı. Biraz sonra tekrar dene."
                        : "Seslendirme için uygun bir plan veya hak gerekiyor."
                    if !EntitlementStore.shared.hasPremiumAccess {
                        showCreditPaywall = true
                    }
                } else if case .unauthorized = error {
                    narrationErrorMessage = "Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap."
                } else {
                    narrationErrorMessage = "Masal seslendirilirken bir sorun oluştu. Lütfen tekrar dene."
                }
            }
        } catch {
            await MainActor.run {
                audioPlayer.isLoading = false
                narrationErrorMessage = "Masal seslendirilirken bir sorun oluştu. Lütfen tekrar dene."
            }
        }
    }
}

private struct AudioActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(HomeDashboardPalette.accentOrange)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
