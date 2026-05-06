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
    @StateObject private var audioPlayer = AudioPlayerViewModel()
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

                if story != nil {
                    storyAudioCard
                        .padding(.horizontal, StoryReadingChrome.horizontalPadding)
                        .padding(.top, 4)
                        .frame(maxWidth: StoryReadingChrome.cardMaxOuterWidth)
                        .frame(maxWidth: .infinity)
                }

                StoryReadingPageControls(currentPage: $currentPage, pageCount: pageCount)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appUIState.isTabBarVisible = false
            currentPage = min(currentPage, max(pageCount - 1, 0))
            storyAudioURLState = story?.audio_url
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
                onPurchaseCompleted: {}
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

    private var storyAudioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sesli Masal")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)

            Text("Bu masalı Burcu anlatıcı sesiyle dinleyebilirsin.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                .fixedSize(horizontal: false, vertical: true)

            if let error = narrationErrorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.9))
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

            HStack(spacing: 10) {
                if let audioURL = storyAudioURLState, !audioURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        audioPlayer.togglePlayPause(urlString: audioURL)
                        narrationErrorMessage = nil
                    } label: {
                        Text(audioPlayer.isPlaying ? "Duraklat" : "Dinle")
                    }
                    .buttonStyle(AudioActionButtonStyle())
                } else {
                    Button {
                        Task { await narrateStoryAndPlay() }
                    } label: {
                        Text(audioPlayer.isLoading ? "Masal seslendiriliyor..." : "Masalı Seslendir")
                    }
                    .buttonStyle(AudioActionButtonStyle())
                    .disabled(audioPlayer.isLoading)
                }
            }

            if narrationErrorMessage == "Seslendirme için yeterli kredin yok." {
                Button("Paketleri Gör") {
                    showCreditPaywall = true
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.15), lineWidth: 1)
        )
    }

    private func narrateStoryAndPlay() async {
        guard let storyId = story?.id else { return }
        if let existing = storyAudioURLState, !existing.isEmpty {
            audioPlayer.play(urlString: existing)
            return
        }

        await MainActor.run {
            narrationErrorMessage = nil
            audioPlayer.isLoading = true
        }

        do {
            let response = try await StoryService.narrateStory(id: storyId)
            await MainActor.run {
                storyAudioURLState = response.audioUrl
                audioPlayer.isLoading = false
                audioPlayer.play(urlString: response.audioUrl)
            }
        } catch let error as StoryAudioServiceError {
            await MainActor.run {
                audioPlayer.isLoading = false
                switch error {
                case .insufficientCredits:
                    narrationErrorMessage = "Seslendirme için yeterli kredin yok."
                case .unauthorized, .storyNotFound, .failed:
                    narrationErrorMessage = error.errorDescription
                }
            }
        } catch {
            await MainActor.run {
                audioPlayer.isLoading = false
                narrationErrorMessage = "Masal seslendirilirken bir hata oluştu."
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
