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
    @ObservedObject private var playback = NarrationPlaybackCenter.shared
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

            if playback.isLoading {
                narrationLoadingOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.2), value: playback.isLoading)
        .onAppear {
            appUIState.isTabBarVisible = false
            currentPage = min(currentPage, max(pageCount - 1, 0))
        }
        .onDisappear {
            appUIState.isTabBarVisible = true
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
            StoryNarrationButton(
                text: storyContent,
                displayTitle: storyTitle,
                storyId: story?.id,
                storyAudioURL: story?.audio_url,
                readerChrome: true,
                compact: compact
            )

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

    private var narrationLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HomeDashboardPalette.accentOrange.opacity(0.16))
                        .frame(width: 72, height: 72)
                    ProgressView()
                        .scaleEffect(1.35)
                        .tint(HomeDashboardPalette.accentOrange)
                }

                Text("Seslendirme hazırlanıyor...")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(HomeDashboardPalette.cardSurface.opacity(0.97))
                    .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 14, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.18), lineWidth: 1)
            )
        }
        .allowsHitTesting(true)
    }
}
