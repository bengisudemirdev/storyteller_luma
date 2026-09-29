import SwiftUI

struct CreateStoryView: View {
    @StateObject private var viewModel: CreateStoryViewModel
    @FocusState private var focusedField: Field?
    @State private var hasLoadedScreenOnce = false
    @ObservedObject private var entitlements = EntitlementStore.shared

    private enum Field: Hashable { case childName; case interest }

    private var themes: [String] {
        let ageGroup = LumaAgeGroup.from(age: viewModel.selectedChild?.age)
        switch ageGroup {
        case .threeToFive:
            // 3-5: daha sakin ve ilişki odaklı temalar
            return ["Uyku", "Eğitici", "Dostluk"]
        case .sixToEight, .nineToEleven:
            return ["Macera", "Uyku", "Eğitici", "Dostluk"]
        }
    }
    let initialChild: ChildModel?
    let initialTheme: String?
    let autoStart: Bool

    init(initialChild: ChildModel? = nil,
         initialTheme: String? = nil,
         autoStart: Bool = false) {
        _viewModel = StateObject(wrappedValue: CreateStoryViewModel())
        self.initialChild = initialChild
        self.initialTheme = initialTheme
        self.autoStart = autoStart
    }

    private var createStoryHero: some View {
        DashboardNightHeroLayout(
            title: "Yeni Masal",
            subtitle: AppBrand.subtitle,
            caption: "Çocuğun için sihirli bir dünya tasarla.",
            minHeight: 240,
            footer: {
                Text("Masallar güvenli, yaşa uygun ve yumuşak bir dille üretilir.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.heroSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        )
    }

    /// Plan bazlı kullanım bilgisi (aylık masal hakkı). Kredi gösterilmez.
    private var planUsageFootnote: String {
        if PortfolioAccessMode.isEnabled { return "Portföy modu: masal oluşturma test için açık." }
        guard let remaining = entitlements.storyRemainingThisMonth, let limit = entitlements.storyLimitMonthly else {
            return " "
        }
        let planName = entitlements.hasFamilyAccess ? "Family" : (entitlements.hasPremiumAccess ? "Premium" : "Ücretsiz plan")
        return "\(planName) • Bu ay kalan masal hakkın: \(remaining) / \(limit)"
    }

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()
                .onTapGesture { focusedField = nil }
            ScrollView {
                VStack(alignment: .leading, spacing: HomeDashboardSectionSpacing.standard) {
                    createStoryHero
                        .padding(.top, 8)

                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kimin için oluşturulsun?")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .padding(.leading, 4)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.children) { child in childSelectionCard(child: child) }
                                }
                                .padding(.horizontal, 5).padding(.bottom, 5)
                            }
                        }

                        VStack(alignment: .leading) {
                            if viewModel.selectedChild != nil {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.selectedChild = nil
                                        viewModel.childName = ""
                                        viewModel.selectedInterests = []
                                        focusedField = .childName
                                    }
                                }) {
                                    HStack {
                                        Label("Başrol: **\(viewModel.childName)**", systemImage: "sparkles")
                                            .font(.subheadline)
                                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                                        Spacer()
                                        Text("Değiştir")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(HomeDashboardPalette.accentOrange.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(HomeDashboardPalette.accentOrange.opacity(0.08))
                                    )
                                }
                            } else {
                                customInputField(label: "Kahramanın Adı", placeholder: "Örn: Ali", text: $viewModel.childName)
                                    .focused($focusedField, equals: .childName)
                            }
                        }

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Masalda Neler Olsun?")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .padding(.leading, 4)
                            if let child = viewModel.selectedChild, let interests = child.interests, !interests.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(interests, id: \.self) { item in interestChip(item: item) }
                                    }
                                    .padding(.horizontal, 5)
                                }
                            }
                            TextField(
                                "",
                                text: $viewModel.interest,
                                prompt: Text("Ekstra detaylar (Konuşan kedi, uçan halı vb.)")
                                    .foregroundStyle(HomeDashboardPalette.muted.opacity(0.85))
                            )
                            .foregroundStyle(HomeDashboardPalette.ink)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(HomeDashboardPalette.cardSurface)
                                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 6, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.18), lineWidth: 1)
                            )
                            .focused($focusedField, equals: .interest)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Masal Teması")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .padding(.leading, 4)
                            Picker("Tema", selection: $viewModel.selectedTheme) {
                                ForEach(themes, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                            .background(
                                LinearGradient(
                                    colors: [
                                        HomeDashboardPalette.accentOrange.opacity(0.12),
                                        HomeDashboardPalette.creamDeep.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Button(action: {
                            focusedField = nil
                            viewModel.createStory()
                        }) {
                            VStack(spacing: 4) {
                                Text("Sihirli Masalı Yaz ✨")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                if let child = viewModel.selectedChild, let fears = child.fears, !fears.isEmpty {
                                    Text("Korkulardan arındırılmış güvenli bölge 🛡️")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .opacity(0.9)
                                }
                            }
                            .foregroundStyle(HomeDashboardPalette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                HomeDashboardPalette.moonGlow,
                                                HomeDashboardPalette.accentOrangeSoft.opacity(0.9)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: HomeDashboardPalette.accentOrange.opacity(0.35), radius: 12, x: 0, y: 4)
                            )
                        }
                        .disabled(viewModel.childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                        .opacity((viewModel.childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) ? 0.55 : 1.0)

                        Text(planUsageFootnote)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .fill(HomeDashboardPalette.cardSurface)
                            .shadow(color: HomeDashboardPalette.cardShadow, radius: 14, x: 0, y: 6)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .overlay { if viewModel.isLoading { LoadingView().ignoresSafeArea() } }
        .fullScreenCover(isPresented: $viewModel.showReaderView) { readerViewContainer }
        .alert("Masal oluşturulamadı", isPresented: $viewModel.showErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu.")
        }
        .sheet(isPresented: $viewModel.showCreditStore) {
            if !PortfolioAccessMode.isEnabled {
                PaywallView(
                    source: .insufficientCredits(required: viewModel.storyCreditCost),
                    onPurchaseCompleted: {
                        viewModel.handlePurchaseCompletion()
                    }
                )
            }
        }
        .onAppear {
            setupSegmentedControl()
            // Kalan hak bilgisi güncel görünsün (ekran her açıldığında).
            Task { await EntitlementStore.shared.refreshFromBackend() }
        }
        .task {
            if hasLoadedScreenOnce { return }
            hasLoadedScreenOnce = true

            await viewModel.fetchChildren()

            // Hızlı tema / dashboard akışından gelinmişse ön seçimleri uygula
            if let child = initialChild {
                viewModel.selectedChild = child
                viewModel.childName = child.name
            }
            if let theme = initialTheme {
                viewModel.selectedTheme = themes.contains(theme) ? theme : (themes.first ?? theme)
            } else {
                // Varsayılan tema, mevcut yaş grubuna göre ilk seçenek
                if let first = themes.first {
                    viewModel.selectedTheme = first
                }
            }
            if autoStart {
                // Çocuk adı hazırsa otomatik masal üret
                viewModel.createStory()
            }
        }
    }

    @ViewBuilder
    private var readerViewContainer: some View {
        StoryReaderView(
            child: viewModel.selectedChild,
            heroDisplayName: viewModel.selectedChild == nil ? viewModel.childName : nil,
            storyTitle: "\(viewModel.childName)'nın Masalı",
            storyContent: viewModel.generatedStory,
            showSaveButton: false,
            story: viewModel.generatedStoryModel,
            onSave: {
                let childId = viewModel.generatedStoryModel?.child_id ?? viewModel.selectedChild?.id
                if let childId {
                    await viewModel.saveStoryToParent(
                        childId: childId,
                        title: "\(viewModel.childName)'nın Masalı",
                        content: viewModel.generatedStory,
                        theme: viewModel.selectedTheme
                    )
                }
                viewModel.showReaderView = false
            }
        )
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private func interestChip(item: String) -> some View {
        let isSelected = viewModel.selectedInterests.contains(item)
        Text(item)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.cardSurface)
            .foregroundStyle(isSelected ? Color.white : HomeDashboardPalette.ink)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(HomeDashboardPalette.accentOrange.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
            )
            .shadow(color: HomeDashboardPalette.cardShadow.opacity(isSelected ? 0.4 : 0), radius: 4, x: 0, y: 2)
            .onTapGesture {
                withAnimation(.spring()) {
                    if isSelected { viewModel.selectedInterests.removeAll { $0 == item } }
                    else { viewModel.selectedInterests.append(item) }
                }
            }
    }

    @ViewBuilder
    func customInputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
                .padding(.leading, 4)
            TextField(
                "",
                text: text,
                prompt: Text(placeholder).foregroundStyle(HomeDashboardPalette.muted.opacity(0.85))
            )
            .foregroundStyle(HomeDashboardPalette.ink)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(HomeDashboardPalette.cardSurface)
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.18), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func childSelectionCard(child: ChildModel) -> some View {
        let isSelected = viewModel.selectedChild?.id == child.id
        VStack(spacing: 8) {
            AvatarGlyphView(emoji: child.safeAvatarEmoji, size: 35, color: HomeDashboardPalette.nightMid)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? HomeDashboardPalette.accentOrange.opacity(0.22) : HomeDashboardPalette.cardSurface)
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? HomeDashboardPalette.accentOrange : Color.clear, lineWidth: 2)
                )
                .shadow(color: HomeDashboardPalette.cardShadow.opacity(isSelected ? 0.25 : 0.12), radius: 4, x: 0, y: 2)
            Text(child.name)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.ink)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                viewModel.selectedChild = child
                viewModel.childName = child.name
                viewModel.selectedInterests = []
                focusedField = nil
            }
        }
    }

    private func setupSegmentedControl() {
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(HomeDashboardPalette.accentOrange)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor(HomeDashboardPalette.ink)], for: .normal)
    }
}
