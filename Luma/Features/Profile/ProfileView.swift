import SwiftUI
import Supabase

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isShowingAddProfile = false
    @State private var childPendingDelete: ChildModel?
    @State private var showDeleteAlert = false
    @State private var isShowingPolicies = false
    @State private var isShowingPaywall = false
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        NavigationView {
            ZStack {
                LumaWarmScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: HomeDashboardSectionSpacing.standard) {
                        profileHero
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Çocuk Profilleri")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundStyle(HomeDashboardPalette.ink)
                            Text("Küçük masal severleri yönetin")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.muted)
                        }
                        .padding(.horizontal, 2)

                        VStack(spacing: 16) {
                            if viewModel.isLoading && viewModel.children.isEmpty {
                                ProgressView()
                                    .tint(HomeDashboardPalette.accentOrange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            } else if viewModel.children.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(viewModel.children) { child in
                                    childRow(child: child)
                                        .onTapGesture {
                                            viewModel.selectedChildForDetail = child
                                            viewModel.isShowingDetailSheet = true
                                        }
                                }
                            }
                            addNewChildButton
                        }

                        safetyPolicySection
                        accountSettingsSection
                        signOutButton
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .onAppear { refreshData() }
            .sheet(isPresented: $isShowingAddProfile) {
                AddChildView(viewModel: viewModel, isShowing: $isShowingAddProfile)
            }
            .sheet(isPresented: $isShowingPolicies) {
                PoliciesDetailView()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(source: .manual)
                    .environmentObject(subscriptionManager)
            }
            .sheet(isPresented: $viewModel.isShowingDetailSheet) {
                if let child = viewModel.selectedChildForDetail {
                    ChildDetailView(
                        child: child,
                        onEdit: {
                            viewModel.beginEditing(child: child)
                        },
                        onDelete: {
                            childPendingDelete = child
                            showDeleteAlert = true
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.isEditSheetPresented) {
                EditChildView(viewModel: viewModel)
            }
            .alert("Profili sil", isPresented: $showDeleteAlert) {
                Button("Vazgeç", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    if let child = childPendingDelete {
                        Task {
                            _ = await viewModel.deleteChild(child)
                        }
                    }
                }
            } message: {
                Text("Bu çocuğa ait profili ve ona bağlı masalları silmek üzeresin. Emin misin?")
            }
        }
    }

    private var profileHero: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.4))
                    .frame(width: 52, height: 52)
                Text(profileInitial)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Profil")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text(viewModel.parentEmail.isEmpty ? "…" : viewModel.parentEmail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private var profileInitial: String {
        let c = viewModel.parentEmail.trimmingCharacters(in: .whitespacesAndNewlines).first
        return c.map { String($0).uppercased() } ?? "?"
    }

    private var safetyPolicySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Politikalarımız")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
            Button {
                isShowingPolicies = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ebeveyn destekli, yaşa uyarlanmış, güvenli hikâye deneyimi")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                        Text("Güvenli hikâye protokolümüzü ve içerik sınırlarımızı ayrıntılı inceleyin.")
                            .font(.caption)
                            .foregroundStyle(HomeDashboardPalette.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.cardSurface)
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Hesap ve Abonelik")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
                .padding(.top, 4)
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
                    .frame(width: 30)
                Text("E-posta")
                    .foregroundStyle(HomeDashboardPalette.ink)
                Spacer()
                Text(viewModel.parentEmail)
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .lineLimit(1)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                    .fill(HomeDashboardPalette.cardSurface)
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 3)
            )

            Button {
                isShowingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plan")
                            .foregroundStyle(HomeDashboardPalette.ink)
                        Text(subscriptionManager.plan.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(subscriptionManager.plan == .premium ? HomeDashboardPalette.accentOrange : HomeDashboardPalette.muted)
                    }
                    Spacer()
                    if subscriptionManager.plan == .free {
                        Text("Premium'a Geç")
                            .font(.caption.bold())
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                    } else {
                        Text("Aktif")
                            .font(.caption.bold())
                            .foregroundStyle(Color.green.opacity(0.85))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.accentOrange.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyStateView: some View {
        Text(viewModel.errorMessage ?? "Henüz bir çocuk profili eklemediniz.")
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundStyle(HomeDashboardPalette.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                    .fill(HomeDashboardPalette.cardSurface.opacity(0.85))
            )
    }

    private var addNewChildButton: some View {
        Button(action: { isShowingAddProfile = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Yeni Çocuk Profili Ekle")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(HomeDashboardPalette.accentOrange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HomeDashboardPalette.accentOrange.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.28), lineWidth: 1)
            )
        }
    }

    private var signOutButton: some View {
        Button(action: { Task { try? await OliaApp.supabase.auth.signOut() } }) {
            Label("Oturumu Kapat", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.red.opacity(0.08))
                )
        }
        .padding(.top, 12)
    }

    private func refreshData() { Task { await viewModel.fetchChildren() } }

    @ViewBuilder
    func childRow(child: ChildModel) -> some View {
        HStack(spacing: 15) {
            Text(child.avatarEmoji)
                .font(.system(size: 40))
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                )
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text("\(child.age) yaşında")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
        )
    }
}

struct ChildDetailView: View {
    let child: ChildModel
    @Environment(\.dismiss) var dismiss
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            LumaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 15) {
                    Text(child.avatarEmoji).font(.system(size: 80))
                        .frame(width: 140, height: 140).background(Circle().fill(LumaTheme.lavender.opacity(0.1)))
                    Text(child.name).font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(LumaTheme.text)
                    Text("\(child.age) Yaşında").foregroundColor(LumaTheme.secondaryText)
                }
                .padding(.vertical, 30)
                ScrollView {
                    VStack(spacing: 20) {
                        detailInfoCard(title: "Neleri Sever?", items: child.interests ?? [], icon: "heart.fill", color: .red)
                        detailInfoCard(title: "Nelerden Kaçınmalı?", items: child.fears ?? [], icon: "shield.fill", color: .blue)
                    }
                    .padding(20)

                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            Label("Profili Düzenle", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LumaTheme.lavender)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }

                        Button {
                            dismiss()
                            onDelete()
                        } label: {
                            Label("Profili Sil", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(LumaTheme.lavender).padding()
            }
        }
    }

    private func detailInfoCard(title: String, items: [String], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline).foregroundColor(color)
            if items.isEmpty { Text("Bilgi girilmemiş").italic().foregroundColor(.gray) }
            else { FlowLayout(items: items, color: color) }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).cornerRadius(20)
    }
}

struct AddChildView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isShowing: Bool
    @State private var currentInterest = ""
    @State private var currentFear = ""

    var body: some View {
        NavigationView {
            ZStack {
                LumaTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Çocuğun Adı").font(.headline).foregroundColor(.black)
                            TextField("Örn: Elif", text: $viewModel.newChildName)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avatar Emoji").font(.headline).foregroundColor(.black)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.availableEmojis, id: \.self) { emoji in
                                        let isSelected = viewModel.selectedEmoji == emoji
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(isSelected ? LumaTheme.lavender.opacity(0.2) : Color.white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isSelected ? LumaTheme.lavender : Color.gray.opacity(0.2), lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                viewModel.selectedEmoji = emoji
                                            }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Yaş Aralığı").font(.headline).foregroundColor(.black)
                            Picker("Yaş Aralığı", selection: $viewModel.newChildAgeGroup) {
                                Text("3-5 yaş").tag(LumaAgeGroup.threeToFive)
                                Text("6-8 yaş").tag(LumaAgeGroup.sixToEight)
                                Text("9-11 yaş").tag(LumaAgeGroup.nineToEleven)
                            }
                            .pickerStyle(.segmented)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Neleri Sever?").font(.headline).foregroundColor(.black)
                            HStack {
                                TextField("Hobi ekle...", text: $currentInterest)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                Button(action: {
                                    if !currentInterest.isEmpty { viewModel.interests.append(currentInterest); currentInterest = "" }
                                }) { Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(LumaTheme.lavender) }
                            }
                            TagLayoutView(tags: $viewModel.interests, color: LumaTheme.lavender)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nelerden Korkar?").font(.headline).foregroundColor(.black)
                            HStack {
                                TextField("Korku ekle...", text: $currentFear)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                Button(action: {
                                    if !currentFear.isEmpty { viewModel.fears.append(currentFear); currentFear = "" }
                                }) { Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.blue) }
                            }
                            TagLayoutView(tags: $viewModel.fears, color: .blue)
                        }
                        Button(action: {
                            Task {
                                let success = await viewModel.addChild(
                                    interests: viewModel.interests,
                                    fears: viewModel.fears
                                )
                                if success { isShowing = false }
                            }
                        }) {
                            if viewModel.isLoading { ProgressView().tint(.white) }
                            else { Text("Profil Oluştur").fontWeight(.bold) }
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                        .background(LumaTheme.lavender).cornerRadius(15).disabled(viewModel.isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Yeni Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Edit Child View

struct EditChildView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentInterest = ""
    @State private var currentFear = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LumaTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Çocuğun Adı").font(.headline).foregroundColor(.black)
                            TextField("Örn: Elif", text: $viewModel.newChildName)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avatar Emoji").font(.headline).foregroundColor(.black)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.availableEmojis, id: \.self) { emoji in
                                        let isSelected = viewModel.selectedEmoji == emoji
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(isSelected ? LumaTheme.lavender.opacity(0.2) : Color.white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isSelected ? LumaTheme.lavender : Color.gray.opacity(0.2), lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                viewModel.selectedEmoji = emoji
                                            }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Yaş Aralığı").font(.headline).foregroundColor(.black)
                            Picker("Yaş Aralığı", selection: $viewModel.newChildAgeGroup) {
                                Text("3-5 yaş").tag(LumaAgeGroup.threeToFive)
                                Text("6-8 yaş").tag(LumaAgeGroup.sixToEight)
                                Text("9-11 yaş").tag(LumaAgeGroup.nineToEleven)
                            }
                            .pickerStyle(.segmented)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Neleri Sever?").font(.headline).foregroundColor(.black)
                            HStack {
                                TextField("Hobi ekle...", text: $currentInterest)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                Button(action: {
                                    if !currentInterest.isEmpty {
                                        viewModel.interests.append(currentInterest)
                                        currentInterest = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(LumaTheme.lavender)
                                }
                            }
                            TagLayoutView(tags: $viewModel.interests, color: LumaTheme.lavender)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nelerden Korkar?").font(.headline).foregroundColor(.black)
                            HStack {
                                TextField("Korku ekle...", text: $currentFear)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                Button(action: {
                                    if !currentFear.isEmpty {
                                        viewModel.fears.append(currentFear)
                                        currentFear = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            TagLayoutView(tags: $viewModel.fears, color: .blue)
                        }
                        Button(action: {
                            Task {
                                let success = await viewModel.updateChild()
                                if success { dismiss() }
                            }
                        }) {
                            if viewModel.isLoading { ProgressView().tint(.white) }
                            else { Text("Değişiklikleri Kaydet").fontWeight(.bold) }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LumaTheme.lavender)
                        .cornerRadius(15)
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct TagLayoutView: View {
    @Binding var tags: [String]
    let color: Color
    var body: some View { FlowLayout(items: tags, color: color) }
}

struct FlowLayout: View {
    let items: [String]
    let color: Color
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
