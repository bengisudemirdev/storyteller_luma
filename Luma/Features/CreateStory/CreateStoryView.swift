import SwiftUI

struct CreateStoryView: View {
    @StateObject private var viewModel: CreateStoryViewModel
    @FocusState private var focusedField: Field?
    @State private var hasLoadedScreenOnce = false
    /// Çocuk listesi yüklenene kadar ad alanı gösterilmez (varsayılan çocuk seçilince alan hiç görünmesin).
    @State private var childrenLoaded = false
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
    /// Sekme canlı tutulduğu için seçili olup olmadığı dışarıdan verilir (başka yerlerden açıldığında varsayılan `true`).
    let isActive: Bool

    init(initialChild: ChildModel? = nil,
         initialTheme: String? = nil,
         autoStart: Bool = false,
         isActive: Bool = true) {
        self.isActive = isActive
        _viewModel = StateObject(wrappedValue: CreateStoryViewModel())
        self.initialChild = initialChild
        self.initialTheme = initialTheme
        self.autoStart = autoStart
    }

    /// Kompakt başlık: ekranın asıl işi form olduğu için büyük hero yerine kısa başlık kullanılır.
    private var createStoryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Yeni Masal")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
            Text("Çocuğun için sihirli bir dünya tasarla.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.sectionCaption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// Butonun üstünde görünen kalan hak bilgisi (aylık/haftalık hak; kredi gösterilmez). Bilinmiyorsa `nil`.
    private var usagePill: (text: String, exhausted: Bool)? {
        if PortfolioAccessMode.isEnabled { return nil }
        guard let remaining = entitlements.storyRemainingThisMonth, let limit = entitlements.storyLimitMonthly else {
            return nil
        }
        let isPaid = entitlements.hasPremiumAccess
        // Ücretsiz plan haftalık, Premium/Family aylık yenilenir (backend `planService` ile aynı).
        if remaining <= 0 {
            return (isPaid ? "Bu ayki masal hakkın doldu" : "Bu haftaki ücretsiz hakkın doldu • Premium ile devam et", true)
        }
        if isPaid {
            return ("Bu ay \(remaining) / \(limit) masal hakkın kaldı", false)
        }
        return (remaining == 1 ? "Bu hafta 1 ücretsiz masal hakkın var" : "Bu hafta \(remaining) ücretsiz masal hakkın var", false)
    }

    @ViewBuilder
    private var usagePillView: some View {
        if let pill = usagePill {
            Label(pill.text, systemImage: pill.exhausted ? "lock.fill" : "sparkles")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(pill.exhausted ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.sectionCaption)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(pill.exhausted ? HomeDashboardPalette.accentOrange.opacity(0.12) : HomeDashboardPalette.creamDeep.opacity(0.7))
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()
                .onTapGesture { focusedField = nil }
            ScrollView {
                VStack(alignment: .leading, spacing: HomeDashboardSectionSpacing.standard) {
                    createStoryHeader
                        .padding(.top, 12)

                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kimin için oluşturulsun?")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .padding(.leading, 4)
                            if !childrenLoaded {
                                HStack(spacing: 15) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        VStack(spacing: 8) {
                                            Circle().fill(HomeDashboardPalette.creamDeep.opacity(0.8)).frame(width: 60, height: 60)
                                            Capsule().fill(HomeDashboardPalette.creamDeep.opacity(0.8)).frame(width: 44, height: 10)
                                        }
                                    }
                                }
                                .padding(.horizontal, 5).padding(.bottom, 5)
                                .accessibilityHidden(true)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.children) { child in childSelectionCard(child: child) }
                                    if !viewModel.children.isEmpty { addOtherNameCard }
                                }
                                .padding(.horizontal, 5).padding(.bottom, 5)
                            }
                        }

                        // Kayıtlı çocuk seçiliyken ad alanı gizlidir; "+" ile başka bir isim yazılır (profil açılmaz).
                        if childrenLoaded && viewModel.selectedChild == nil {
                            customInputField(
                                label: viewModel.children.isEmpty ? "Kahramanın Adı" : "Başka Kahramanın Adı",
                                placeholder: "Örn: Ali",
                                text: $viewModel.childName
                            )
                            .focused($focusedField, equals: .childName)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Masalda Neler Olsun?")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .padding(.leading, 4)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(interestChipItems, id: \.self) { item in interestChip(item: item) }
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                            }
                            TextField(
                                "",
                                text: $viewModel.interest,
                                prompt: Text("Ya da kendin yaz (ör. konuşan kedi)")
                                    .foregroundStyle(HomeDashboardPalette.muted.opacity(0.85))
                            )
                            .lumaInputText()
                            .lumaInputBox(focused: focusedField == .interest)
                            .focused($focusedField, equals: .interest)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bu Akşam Ne Var?")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .padding(.leading, 4)
                            Text("İstersen masal, çocuğunun yaşadığı bir duruma şefkatle dokunsun.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 4)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(CreateStoryViewModel.situations, id: \.self) { item in situationChip(item: item) }
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                            }
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

                        usagePillView

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

                        Label("Masallar güvenli, yaşa uygun ve yumuşak bir dille üretilir.", systemImage: "shield.checkered")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.sectionCaption)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
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
        .overlay { if viewModel.isLoading { LoadingView(onCancel: { viewModel.cancelGeneration() }).ignoresSafeArea() } }
        .fullScreenCover(isPresented: $viewModel.showReaderView) { readerViewContainer }
        .alert("Masal oluşturulamadı", isPresented: $viewModel.showErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu.")
        }
        .sheet(isPresented: $viewModel.showCreditStore) {
            if !PortfolioAccessMode.isEnabled {
                PaywallView(
                    source: .insufficientCredits(required: 0),
                    onPurchaseCompleted: {
                        viewModel.handlePurchaseCompletion()
                    }
                )
            }
        }
        .onChange(of: isActive) { _, nowActive in
            // Sekmeye her dönüşte kalan hak bilgisi güncel görünsün.
            guard nowActive, childrenLoaded else { return }
            Task {
                await EntitlementStore.shared.refreshFromBackend()
                // Profil sekmesinde çocuk eklenmiş/silinmiş olabilir: listeyi sessizce yenile, seçimi koru ya da düzelt.
                await viewModel.fetchChildren(forceRefresh: true)
                if let current = viewModel.selectedChild, let fresh = viewModel.children.first(where: { $0.id == current.id }) {
                    // Profilde düzenlenmiş olabilir (ad, ilgi alanları): güncel kaydı kullan. Ad alanı kullanıcının
                    // kendi yazdığı bir isim olmadığı için yeni adla eşitlenir.
                    viewModel.selectedChild = fresh
                    viewModel.childName = fresh.name
                } else if let current = viewModel.selectedChild, !viewModel.children.contains(where: { $0.id == current.id }) {
                    viewModel.selectedChild = viewModel.children.first
                    viewModel.childName = viewModel.selectedChild?.name ?? ""
                } else if viewModel.selectedChild == nil, viewModel.childName.isEmpty, let first = viewModel.children.first {
                    viewModel.selectedChild = first
                    viewModel.childName = first.name
                }
            }
        }
        .onChange(of: viewModel.selectedChild?.id) { _, _ in
            if !themes.contains(viewModel.selectedTheme), let first = themes.first {
                viewModel.selectedTheme = first
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

            // Hızlı tema / dashboard akışından gelinmişse ön seçimleri uygula; yoksa ilk çocuk varsayılan seçilir.
            if let child = initialChild {
                viewModel.selectedChild = child
                viewModel.childName = child.name
            } else if viewModel.selectedChild == nil, let first = viewModel.children.first {
                viewModel.selectedChild = first
                viewModel.childName = first.name
            }
            childrenLoaded = true
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
    /// Yapay zekanın ürettiği başlık; yoksa "Defne'nin Masalı" biçiminde doğru ekli yedek başlık.
    private var generatedStoryTitle: String {
        let ai = viewModel.generatedStoryModel?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ai.isEmpty ? TurkishGrammar.fallbackStoryTitle(for: viewModel.childName) : ai
    }

    private var readerViewContainer: some View {
        StoryReaderView(
            child: viewModel.selectedChild,
            heroDisplayName: viewModel.selectedChild == nil ? viewModel.childName : nil,
            storyTitle: generatedStoryTitle,
            storyContent: viewModel.generatedStory,
            showSaveButton: false,
            story: viewModel.generatedStoryModel,
            // Masal üretilir üretilmez sunucuya kaydedilir; elle "Kaydet" gerekmez (eski düğme hiçbir şey yapmıyordu).
            onSave: nil,
            showsAutoSavedNotice: viewModel.generatedStoryModel != nil
        )
        .ignoresSafeArea(edges: .bottom)
    }

    /// Çocuğun ilgi alanları önce, ardından (tekrar etmeden) genel fikirler.
    private var interestChipItems: [String] {
        let own = viewModel.selectedChild?.interests ?? []
        let ideas = CreateStoryViewModel.ideaSuggestions.filter { idea in
            // "Uzay" varsa "Uzay yolculuğu" tekrar gösterilmez.
            !own.contains { owned in
                idea.localizedCaseInsensitiveContains(owned) || owned.localizedCaseInsensitiveContains(idea)
            }
        }
        return own + ideas
    }

    @ViewBuilder
    private func situationChip(item: String) -> some View {
        let isSelected = viewModel.selectedSituation == item
        Text(item)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? HomeDashboardPalette.nightMid : HomeDashboardPalette.cardSurface)
            .foregroundStyle(isSelected ? Color.white : HomeDashboardPalette.ink)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(HomeDashboardPalette.nightMid.opacity(isSelected ? 0 : 0.28), lineWidth: 1)
            )
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.spring()) {
                    viewModel.selectedSituation = isSelected ? nil : item
                }
            }
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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
            .lumaInputText()
            .lumaInputBox()
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

    /// "+" kartı: kayıtlı çocuk dışında başka bir isim için masal yazmak.
    private var addOtherNameCard: some View {
        let isSelected = viewModel.selectedChild == nil
        return VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? HomeDashboardPalette.accentOrange.opacity(0.22) : HomeDashboardPalette.cardSurface)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            HomeDashboardPalette.accentOrange.opacity(isSelected ? 1 : 0.45),
                            style: StrokeStyle(lineWidth: isSelected ? 2 : 1.5, dash: isSelected ? [] : [4, 3])
                        )
                )
                .shadow(color: HomeDashboardPalette.cardShadow.opacity(isSelected ? 0.25 : 0.12), radius: 4, x: 0, y: 2)
            Text("Başka")
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.ink)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring()) {
                viewModel.selectedChild = nil
                viewModel.childName = ""
                viewModel.selectedInterests = []
            }
            focusedField = .childName
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Başka bir isim için masal yaz")
        .accessibilityAddTraits(.isButton)
    }

    private func setupSegmentedControl() {
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(HomeDashboardPalette.accentOrange)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor(HomeDashboardPalette.ink)], for: .normal)
    }
}
