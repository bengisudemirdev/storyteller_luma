import SwiftUI

/// Kayıtlı masalların tam listesi (ana sayfadaki “Son Masalların” → “Tümünü Gör”).
struct SavedStoriesLibraryView: View {
    private static let libraryFetchLimit = 100

    @State private var stories: [StoryModel] = []
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            HomeMagicalScreenBackground()

            Group {
                if isLoading && stories.isEmpty {
                    ProgressView()
                        .tint(HomeDashboardPalette.accentOrange)
                        .scaleEffect(1.15)
                } else if stories.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(stories) { story in
                                NavigationLink {
                                    StoryReaderView(
                                        child: nil,
                                        storyTitle: story.title,
                                        storyContent: story.content,
                                        showSaveButton: false,
                                        story: story,
                                        onSave: nil
                                    )
                                } label: {
                                    SavedStoryLibraryRow(story: story)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("Masallarım")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStories()
        }
        .refreshable {
            await loadStories()
        }
        .onReceive(NotificationCenter.default.publisher(for: .lumaSavedStoriesDidChange)) { _ in
            Task { await loadStories() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 44))
                .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.85))
            Text(loadFailed ? "Masallar yüklenemedi. Bağlantını kontrol edip tekrar dene." : "Henüz kayıtlı masal yok")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
                .multilineTextAlignment(.center)
            if loadFailed {
                Button {
                    Task { await loadStories() }
                } label: {
                    Text("Tekrar dene")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(HomeDashboardPalette.accentOrange.opacity(0.14))
                        )
                }
                .buttonStyle(.plain)
            }
            NavigationLink {
                CreateStoryView()
            } label: {
                Text("Masal oluştur")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(HomeDashboardPalette.accentOrange)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(32)
    }

    @MainActor
    private func loadStories() async {
        if stories.isEmpty {
            isLoading = true
        }
        loadFailed = false
        do {
            stories = try await StoryService.fetchSavedStories(limit: Self.libraryFetchLimit)
        } catch {
            loadFailed = true
            AppLogger.error("savedStories.library.load.failed", ["error": String(describing: error)])
        }
        isLoading = false
    }
}

private struct SavedStoryLibraryRow: View {
    let story: StoryModel

    private var thumbShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 18,
                bottomLeading: 12,
                bottomTrailing: 12,
                topTrailing: 18
            ),
            style: .continuous
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                thumbShape
                    .fill(
                        LinearGradient(
                            colors: [
                                HomeDashboardPalette.accentOrange.opacity(0.28),
                                HomeDashboardPalette.accentOrangeSoft.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let urlStr = story.cover_image_url, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ProgressView()
                                .tint(HomeDashboardPalette.accentOrange)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                LinearGradient(
                    colors: [.white.opacity(0.12), .black.opacity(0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(thumbShape)
                .allowsHitTesting(false)

                if story.cover_image_url == nil || story.cover_image_url?.isEmpty == true {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.9))
                }
            }
            .frame(width: 88, height: 110)
            .clipShape(thumbShape)

            VStack(alignment: .leading, spacing: 6) {
                Text(story.title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if !story.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(story.theme)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        .lineLimit(2)
                }

                if let date = story.created_at {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeDashboardPalette.muted.opacity(0.65))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                .fill(HomeDashboardPalette.dashboardCanvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius + 2, style: .continuous)
                .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
        )
        .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 8, x: 0, y: 4)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
}
