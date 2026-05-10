import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showFirstLaunchPolicy = false

    var body: some View {
        NavigationStack {
            ZStack {
                HomeMagicalScreenBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: HomeDashboardSectionSpacing.standard) {
                        HomeHeroSection()
                            .padding(.top, 12)

                        DashboardQuickActionsSection()

                        ClassicTalesSection(classicTales: viewModel.classicTales)

                        DashboardRecentStoriesSection(stories: viewModel.recentStories)
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                    .padding(.bottom, 132)
                }
                .refreshable {
                    await viewModel.loadDashboard(forceRefresh: true)
                }

                if viewModel.isLoadingInitial {
                    Color.black.opacity(0.05)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(Color(hex: "E8956A"))
                        .scaleEffect(1.2)
                }
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .lumaSavedStoriesDidChange)) { _ in
            Task { await viewModel.loadDashboard(forceRefresh: true) }
        }
        .onAppear {
            if !viewModel.hasSeenPolicyOnboarding {
                showFirstLaunchPolicy = true
                viewModel.markPolicyOnboardingSeen()
            }
        }
        .alert("Olia nasıl çalışır?", isPresented: $showFirstLaunchPolicy) {
            Button("Anladım", role: .cancel) { }
        } message: {
            Text("""
            Olia'nın temel protokolü: ebeveyn destekli, yaşa uyarlanmış, güvenli hikâye deneyimi.

            • Masallar çocuğun yaş grubuna göre yumuşak bir dil ve uygun uzunlukta üretilir.
            • Şiddet, ağır korku ve aşağılayıcı temalar filtrelenir ya da güvenli alternatiflere dönüştürülür.
            • Çocuk karakter asla yalnız ve çaresiz bırakılmaz; hikâyeler güvenli ve iyi hissettiren bir sonla biter.

            Ayrıntılı politikalarımızı Profil sekmesindeki “Politikalarımız” alanından istediğiniz zaman inceleyebilirsiniz.
            """)
        }
    }
}

/// Section spacing shared by Home layout (re-export friendly constant).
enum HomeDashboardSectionSpacing {
    /// Kartlar ve bölümler arasında daha ferah dikey ritim.
    static let standard: CGFloat = 36
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var children: [ChildModel] = []
    @Published var recentStories: [StoryModel] = []
    /// `GET /v1/classic-tales`; hata veya boş yanıtta `ClassicTaleItem.bundledTales` kullanılır.
    @Published var classicTales: [ClassicTaleItem] = ClassicTaleItem.bundledTales
    @Published var isLoadingInitial: Bool = false
    @Published var selectedChild: ChildModel? = nil
    @Published private(set) var hasSeenPolicyOnboarding: Bool = UserDefaults.standard.bool(forKey: "luma_has_seen_policy_onboarding")
    private var hasLoadedDashboardOnce = false

    func loadDashboard(forceRefresh: Bool = false) async {
        if hasLoadedDashboardOnce && !forceRefresh {
            return
        }

        if children.isEmpty && recentStories.isEmpty {
            isLoadingInitial = true
        }

        do {
            async let childrenTask: [ChildModel] = fetchChildren()
            async let storiesTask: [StoryModel] = fetchStories()
            let (fetchedChildren, fetchedStories) = try await (childrenTask, storiesTask)
            let fetchedClassics = await fetchClassicTalesFromAPI()
            self.children = fetchedChildren
            self.recentStories = fetchedStories
            self.classicTales = fetchedClassics

            Task(priority: .utility) {
                await ClassicTaleRemoteNarrationFetcher.prefetchRemoteAudio(for: fetchedClassics)
            }

            if selectedChild == nil {
                selectedChild = fetchedChildren.first
            } else if let current = selectedChild,
                      !fetchedChildren.contains(where: { $0.id == current.id }) {
                selectedChild = fetchedChildren.first
            }

            hasLoadedDashboardOnce = true
        } catch {
            AppLogger.error("dashboard.load.failed", [
                "errorType": String(describing: type(of: error)),
                "error": String(describing: error)
            ])
        }

        isLoadingInitial = false
    }

    func markPolicyOnboardingSeen() {
        hasSeenPolicyOnboarding = true
        UserDefaults.standard.set(true, forKey: "luma_has_seen_policy_onboarding")
    }

    private func fetchChildren() async throws -> [ChildModel] {
        do {
            return try await ChildrenAPIService.fetchChildren()
        } catch {
            AppLogger.error("children.fetch.failed", [
                "context": "HomeViewModel",
                "errorType": String(describing: type(of: error)),
                "error": String(describing: error)
            ])
            return []
        }
    }

    private func fetchStories() async throws -> [StoryModel] {
        do {
            let stories = try await StoryService.fetchSavedStories()
            return stories
        } catch {
            AppLogger.error("stories.fetch.failed", [
                "context": "HomeViewModel",
                "errorType": String(describing: type(of: error)),
                "error": String(describing: error)
            ])
            return []
        }
    }

    private func fetchClassicTalesFromAPI() async -> [ClassicTaleItem] {
        do {
            let tales = try await StoryService.fetchClassicTales()
            return tales.isEmpty ? ClassicTaleItem.bundledTales : tales
        } catch {
            AppLogger.error("classic_tales.fetch.failed", [
                "context": "HomeViewModel",
                "errorType": String(describing: type(of: error)),
                "error": String(describing: error)
            ])
            return ClassicTaleItem.bundledTales
        }
    }
}

// MARK: - Children Section (Profil / diğer ekranlar için saklı)

struct ChildrenSection: View {
    let children: [ChildModel]
    @Binding var selectedChild: ChildModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Çocukların")
                    .font(.headline)
                    .foregroundColor(LumaTheme.text)
                Spacer()
            }

            if children.isEmpty {
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LumaTheme.lavender.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(LumaTheme.lavender)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Henüz çocuk profili yok")
                                .foregroundColor(LumaTheme.text)
                                .font(.subheadline.weight(.semibold))
                            Text("Masalları kişiselleştirmek için bir çocuk profili oluştur.")
                                .foregroundColor(LumaTheme.secondaryText)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                            .shadow(color: LumaTheme.softShadow, radius: 8, x: 0, y: 3)
                    )
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(children) { child in
                            ChildSelectableCard(
                                child: child,
                                isSelected: selectedChild?.id == child.id
                            )
                            .onTapGesture {
                                if selectedChild?.id == child.id {
                                    selectedChild = nil
                                } else {
                                    selectedChild = child
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let child = selectedChild {
                    SelectedChildDetailSection(child: child)
                        .padding(.top, 8)
                }
            }
        }
    }
}

struct ChildCard: View {
    let child: ChildModel

    var body: some View {
        VStack(spacing: 8) {
            Text(child.avatarEmoji)
                .font(.system(size: 36))
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(LumaTheme.lavender.opacity(0.15))
                )

            Text(child.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.text)

            Text("\(child.age) yaş")
                .font(.caption)
                .foregroundColor(LumaTheme.secondaryText)
        }
        .padding(12)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: LumaTheme.softShadow, radius: 8, x: 0, y: 3)
        )
    }
}

struct ChildSelectableCard: View {
    let child: ChildModel
    let isSelected: Bool

    var body: some View {
        ChildCard(child: child)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? LumaTheme.lavender : Color.clear,
                        lineWidth: 2
                    )
            )
    }
}

struct SelectedChildDetailSection: View {
    let child: ChildModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(child.name) hakkında")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LumaTheme.text)

            HStack(spacing: 8) {
                Label("\(child.age) yaş", systemImage: "figure.child")
                    .font(.caption)
                    .foregroundColor(LumaTheme.secondaryText)
                if !child.avatarEmoji.isEmpty {
                    Text(child.avatarEmoji)
                }
            }

            if let interests = child.interests, !interests.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neleri sever?")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LumaTheme.text)
                    WrapTagsView(tags: interests, color: LumaTheme.lavender)
                }
            }

            if let fears = child.fears, !fears.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nelerden kaçınmalı?")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LumaTheme.text)
                    WrapTagsView(tags: fears, color: .blue)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: LumaTheme.softShadow, radius: 6, x: 0, y: 3)
        )
    }
}

struct WrapTagsView: View {
    let tags: [String]
    let color: Color

    var body: some View {
        FlexibleView(
            data: tags,
            spacing: 6,
            alignment: .leading
        ) { tag in
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.12))
                .foregroundColor(color)
                .clipShape(Capsule())
        }
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    init(data: Data,
         spacing: CGFloat,
         alignment: HorizontalAlignment,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            var currentWidth: CGFloat = 0
            GeometryReader { geometry in
                self.generateContent(in: geometry, currentWidth: &currentWidth)
            }
            .frame(height: calculateHeight(containerWidth: UIScreen.main.bounds.width - 40))
        }
    }

    private func generateContent(in geometry: GeometryProxy, currentWidth: inout CGFloat) -> some View {
        var width = currentWidth
        let items = Array(data)
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                        }
                        let result = width
                        if let last = items.last, item == last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
            }
        }
    }

    private func calculateHeight(containerWidth: CGFloat) -> CGFloat {
        40
    }
}
