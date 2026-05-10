import SwiftUI
import Supabase

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isShowingAddProfile = false
    @State private var childPendingDelete: ChildModel?
    @State private var showDeleteAlert = false
    @State private var isShowingPolicies = false
    @State private var isShowingPaywall = false
    @State private var isShowingFeedbackSheet = false
    @State private var isShowingAccountSecuritySheet = false
    @State private var accountSecurityDetent: PresentationDetent = .large
    @State private var hasLoadedScreenOnce = false
    @ObservedObject private var creditBalance = CreditBalanceViewModel.shared
    @ObservedObject private var entitlements = EntitlementStore.shared

    private enum ProfileCardMetrics {
        static let horizontalPadding: CGFloat = 14
        static let minHeight: CGFloat = 78
        static let iconSize: CGFloat = 40
    }

    var body: some View {
        NavigationView {
            ZStack {
                LumaWarmScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: HomeDashboardSectionSpacing.standard) {
                        profileHero
                            .padding(.top, 8)

                        creditSection

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
                        feedbackSection
                        accountSettingsSection
                        signOutButton
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .task {
                if hasLoadedScreenOnce { return }
                hasLoadedScreenOnce = true
                await EntitlementStore.shared.refreshFromBackend()
                await SubscriptionManager.shared.refreshPlanFromServer()
                await creditBalance.syncFromBackend()
                await viewModel.fetchChildren()
            }
            .sheet(isPresented: $isShowingAddProfile) {
                AddChildView(viewModel: viewModel, isShowing: $isShowingAddProfile)
                    .presentationDetents([.large])
                    .presentationContentInteraction(.scrolls)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
            .sheet(isPresented: $isShowingPolicies) {
                PoliciesDetailView()
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(source: .manual)
            }
            .sheet(isPresented: $isShowingFeedbackSheet) {
                ProfileFeedbackSheet(
                    recipientEmail: AppConfig.feedbackRecipientEmail,
                    userEmail: viewModel.parentEmail
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $isShowingAccountSecuritySheet) {
                AccountSecuritySheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large], selection: $accountSecurityDetent)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .onAppear {
                        accountSecurityDetent = .large
                    }
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
                HStack(spacing: 14) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: ProfileCardMetrics.iconSize, height: ProfileCardMetrics.iconSize)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ebeveyn destekli, yaşa uyarlanmış, güvenli hikâye deneyimi")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                        Text("Güvenli hikâye protokolümüzü ve içerik sınırlarımızı ayrıntılı inceleyin.")
                            .font(.caption)
                            .foregroundStyle(HomeDashboardPalette.muted)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                }
                .padding(ProfileCardMetrics.horizontalPadding)
                .frame(minHeight: ProfileCardMetrics.minHeight)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.cardSurface)
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Geri bildirim")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
            Button {
                isShowingFeedbackSheet = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: ProfileCardMetrics.iconSize, height: ProfileCardMetrics.iconSize)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bize yaz")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HomeDashboardPalette.ink)
                        Text("Öneri, hata veya soruların için e-posta ile ilet.")
                            .font(.caption)
                            .foregroundStyle(HomeDashboardPalette.muted)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.85))
                }
                .padding(ProfileCardMetrics.horizontalPadding)
                .frame(minHeight: ProfileCardMetrics.minHeight)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.cardSurface)
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Planın")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)

            if entitlements.hasPremiumAccess {
                HStack(spacing: 14) {
                    Image(systemName: entitlements.hasFamilyAccess ? "figure.2.and.child.holdinghands" : "star.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: ProfileCardMetrics.iconSize, height: ProfileCardMetrics.iconSize)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entitlements.hasFamilyAccess ? "Family üyeliğin aktif" : "Premium üyeliğin aktif")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HomeDashboardPalette.ink)
                        Text(
                            "Kalan masal hakkı: \(entitlements.storyRemainingThisMonth ?? 0) • Sesli masal hakkı: \(entitlements.voiceRemainingThisMonth ?? 0)"
                        )
                        .font(.caption2)
                        .foregroundStyle(HomeDashboardPalette.muted)
                        if (entitlements.extraVoiceCredits ?? 0) > 0 {
                            Text("Ek ses hakları: \(entitlements.extraVoiceCredits ?? 0)")
                                .font(.caption2)
                                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        }
                        Text("Kredi bakiyesi (kampanya / hediye): \(creditBalance.balance)")
                            .font(.caption2)
                            .foregroundStyle(HomeDashboardPalette.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(ProfileCardMetrics.horizontalPadding)
                .frame(minHeight: ProfileCardMetrics.minHeight)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.cardSurface)
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
                )
            } else {
                Button {
                    Task {
                        await EntitlementStore.shared.refreshFromBackend()
                        await SubscriptionManager.shared.refreshPlanFromServer()
                        if !EntitlementStore.shared.hasPremiumAccess {
                            isShowingPaywall = true
                        }
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(HomeDashboardPalette.accentOrange)
                            .frame(width: ProfileCardMetrics.iconSize, height: ProfileCardMetrics.iconSize)
                            .background(
                                Circle()
                                    .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Premium’a geç")
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .font(.subheadline.weight(.semibold))
                            Text(
                                "Kalan masal hakkı: \(entitlements.storyRemainingThisMonth ?? 0) • Sesli masal hakkı: \(entitlements.voiceRemainingThisMonth ?? 0)"
                            )
                            .font(.caption2)
                            .foregroundStyle(HomeDashboardPalette.muted)
                            Text("Kişiselleştirilmiş masallar ve doğal anlatıcı sesi için plan seç.")
                                .font(.caption2)
                                .foregroundStyle(HomeDashboardPalette.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.85))
                    }
                    .padding(ProfileCardMetrics.horizontalPadding)
                    .frame(minHeight: ProfileCardMetrics.minHeight)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .fill(HomeDashboardPalette.cardSurface)
                            .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Hesap")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
                .padding(.top, 4)
            Button {
                isShowingAccountSecuritySheet = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: ProfileCardMetrics.iconSize, height: ProfileCardMetrics.iconSize)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("E-posta ve şifre")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HomeDashboardPalette.ink)
                        Text(viewModel.parentEmail)
                            .font(.caption)
                            .foregroundStyle(HomeDashboardPalette.muted)
                            .lineLimit(1)
                        Text("Hesap bilgilerini güncelle")
                            .font(.caption)
                            .foregroundStyle(HomeDashboardPalette.muted)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange.opacity(0.85))
                }
                .padding(ProfileCardMetrics.horizontalPadding)
                .frame(minHeight: ProfileCardMetrics.minHeight)
                .background(
                    RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                        .fill(HomeDashboardPalette.cardSurface)
                        .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
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

    @ViewBuilder
    func childRow(child: ChildModel) -> some View {
        HStack(spacing: 15) {
            AvatarGlyphView(emoji: child.safeAvatarEmoji, size: 40, color: HomeDashboardPalette.nightMid)
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

private struct AccountSecuritySheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var statusMessage: String?
    @State private var isErrorStatus = false
    @State private var showDeleteAccountConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                LumaWarmScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Hesap E-postası")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.ink)

                            TextField("ornek@eposta.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.9))
                                )

                            Button {
                                Task {
                                    await updateEmail()
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("E-postayı Güncelle")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(viewModel.isLoading)
                            .background(HomeDashboardPalette.accentOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Divider()
                            .padding(.vertical, 4)

                        Group {
                            Text("Şifre Değiştir")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.ink)

                            SecureField("Yeni şifre (en az 6 karakter)", text: $newPassword)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.9))
                                )

                            SecureField("Yeni şifre (tekrar)", text: $confirmPassword)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.9))
                                )

                            Button {
                                Task {
                                    await updatePassword()
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Şifreyi Güncelle")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(viewModel.isLoading)
                            .background(HomeDashboardPalette.nightMid)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Divider()
                            .padding(.vertical, 4)

                        Group {
                            Text("Hesabı Sil")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.ink)

                            Text("Bu işlem geri alınamaz. Tüm profil verilerin kalıcı olarak silinir.")
                                .font(.footnote)
                                .foregroundStyle(HomeDashboardPalette.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                showDeleteAccountConfirm = true
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Hesabımı Sil")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(viewModel.isLoading)
                            .background(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if let statusMessage, !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(isErrorStatus ? Color.red.opacity(0.9) : Color.green.opacity(0.85))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill((isErrorStatus ? Color.red : Color.green).opacity(0.1))
                                )
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Hesap Güvenliği")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onAppear {
                email = viewModel.parentEmail
            }
            .alert("Hesabını silmek istediğine emin misin?", isPresented: $showDeleteAccountConfirm) {
                Button("Vazgeç", role: .cancel) { }
                Button("Hesabımı Sil", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("Bu işlem geri alınamaz. Hesabın ve ilişkili verilerin silinecektir.")
            }
        }
    }

    private func updateEmail() async {
        do {
            try await viewModel.updateAccountEmail(email)
            isErrorStatus = false
            statusMessage = "E-posta güncelleme isteği gönderildi. Gerekirse yeni adresini doğrula."
        } catch {
            isErrorStatus = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? error.userFacingTurkishMessage
        }
    }

    private func updatePassword() async {
        do {
            try await viewModel.updateAccountPassword(newPassword: newPassword, confirmPassword: confirmPassword)
            isErrorStatus = false
            statusMessage = "Şifre başarıyla güncellendi."
            newPassword = ""
            confirmPassword = ""
        } catch {
            isErrorStatus = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? error.userFacingTurkishMessage
        }
    }

    private func deleteAccount() async {
        do {
            let message = try await viewModel.deleteAccount()
            isErrorStatus = false
            statusMessage = message
            dismiss()
        } catch {
            isErrorStatus = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? error.userFacingTurkishMessage
        }
    }
}

struct ChildDetailView: View {
    let child: ChildModel
    @Environment(\.dismiss) var dismiss
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 8)

                    childDetailHero

                    VStack(spacing: 14) {
                        detailInfoCard(
                            title: "Neleri sever?",
                            subtitle: "Masallarda öne çıkarırız",
                            items: child.interests ?? [],
                            icon: "heart.fill",
                            accent: HomeDashboardPalette.accentOrange
                        )
                        detailInfoCard(
                            title: "Nelerden kaçınmalı?",
                            subtitle: "Hikâyelerde yumuşatırız",
                            items: child.fears ?? [],
                            icon: "shield.fill",
                            accent: HomeDashboardPalette.nightMid.opacity(0.85)
                        )
                    }
                    .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                    .padding(.top, 8)

                    VStack(spacing: 10) {
                        Button {
                            dismiss()
                            onEdit()
                        } label: {
                            Label("Profili düzenle", systemImage: "pencil")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    HomeDashboardPalette.moonGlow,
                                                    HomeDashboardPalette.accentOrangeSoft.opacity(0.92)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: HomeDashboardPalette.accentOrange.opacity(0.35), radius: 12, x: 0, y: 5)
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                            onDelete()
                        } label: {
                            Label("Profili sil", systemImage: "trash")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.92))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.red.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.red.opacity(0.22), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                    .padding(.top, 22)
                    .padding(.bottom, 28)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
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
            .padding(.top, 12)
            .padding(.trailing, 16)
            .accessibilityLabel(String(localized: "Kapat"))
        }
    }

    private var childDetailHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                HomeDashboardPalette.accentOrangeSoft.opacity(0.45),
                                HomeDashboardPalette.creamDeep
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 124, height: 124)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        HomeDashboardPalette.accentOrange.opacity(0.55),
                                        HomeDashboardPalette.accentOrangeSoft.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 14, x: 0, y: 8)

                AvatarGlyphView(emoji: child.safeAvatarEmoji, size: 56, color: HomeDashboardPalette.nightMid)
            }

            Text(child.name)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
                .multilineTextAlignment(.center)

            Text("\(child.age) yaşında")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func detailInfoCard(title: String, subtitle: String, items: [String], icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(accent.opacity(0.12))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
                Spacer(minLength: 0)
            }

            if items.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "text.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption.opacity(0.85))
                    Text("Henüz bilgi eklenmedi — düzenleyerek ekleyebilirsin.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } else {
                FlowLayout(items: items, color: accent)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.2),
                            HomeDashboardPalette.cardEdgeStroke
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct AddChildView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isShowing: Bool
    @State private var currentInterest = ""
    @State private var currentFear = ""

    private enum AddChildField: Hashable {
        case name
        case interest
        case fear
    }

    @FocusState private var focusedField: AddChildField?

    /// 10 emoji → 2 satır, kompakt hücreler.
    private let emojiGridColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            // ViewThatFits + sheet bazen klavye/odak sorununa yol açıyor; formu her zaman kaydırılabilir tut.
            ScrollView(showsIndicators: false) {
                addChildFormContent
                    .padding(.horizontal, 16)
                    .padding(.top, 36)
                    .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    /// Tek sütunda tüm form; mümkünse kaydırmasız gösterilir.
    private var addChildFormContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow

            avatarPreviewHero

            addChildSectionCard(title: "İsim", subtitle: "Masallarda böyle sesleniriz") {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(HomeDashboardPalette.accentOrangeSoft.opacity(0.35))
                        )
                    TextField("Örn: Elif", text: $viewModel.newChildName)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.ink)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .name)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HomeDashboardPalette.creamDeep.opacity(0.65))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(HomeDashboardPalette.accentOrange.opacity(0.15), lineWidth: 1)
                )
            }

            addChildSectionCard(title: "Avatar", subtitle: "Profilde görünsün") {
                LazyVGrid(columns: emojiGridColumns, spacing: 6) {
                    ForEach(viewModel.availableEmojis, id: \.self) { emoji in
                        addChildEmojiCell(emoji: emoji, isSelected: viewModel.selectedEmoji == emoji) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                viewModel.selectedEmoji = emoji
                            }
                        }
                    }
                }
            }

            addChildSectionCard(title: "Yaş", subtitle: "Dil ve tema uyumu") {
                Picker("Yaş aralığı", selection: $viewModel.newChildAgeGroup) {
                    Text("3–5").tag(LumaAgeGroup.threeToFive)
                    Text("6–8").tag(LumaAgeGroup.sixToEight)
                    Text("9–11").tag(LumaAgeGroup.nineToEleven)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .tint(LumaTheme.lavender)
            }

            addChildSectionCard(title: "İlgi ve hassasiyet", subtitle: "İsteğe bağlı") {
                Text("Sevdikleri")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                addChildTagInputRow(
                    placeholder: "Örn: dinazorlar",
                    text: $currentInterest,
                    focus: .interest,
                    accent: HomeDashboardPalette.accentOrange
                ) {
                    let t = currentInterest.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    viewModel.interests.append(t)
                    currentInterest = ""
                }
                TagLayoutView(tags: $viewModel.interests, color: HomeDashboardPalette.accentOrange)

                Text("Kaçınılacaklar")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .padding(.top, 6)
                addChildTagInputRow(
                    placeholder: "Örn: karanlık",
                    text: $currentFear,
                    focus: .fear,
                    accent: HomeDashboardPalette.nightMid
                ) {
                    let t = currentFear.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    viewModel.fears.append(t)
                    currentFear = ""
                }
                TagLayoutView(tags: $viewModel.fears, color: HomeDashboardPalette.nightMid)
            }

            if let err = viewModel.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.88))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                    )
            }

            submitButton
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Yeni çocuk profili")
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text("Masal dünyasını tanıyalım")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 8)
            Button {
                isShowing = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(HomeDashboardPalette.cardSurface)
                            .shadow(color: HomeDashboardPalette.cardShadow, radius: 6, x: 0, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Kapat"))
        }
    }

    private var addChildPreviewNameTrimmed: String {
        viewModel.newChildName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var addChildPreviewShowsName: Bool {
        !addChildPreviewNameTrimmed.isEmpty
    }

    private var avatarPreviewHero: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HomeDashboardPalette.accentOrangeSoft.opacity(0.5),
                                HomeDashboardPalette.accentOrange.opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 34
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        LumaTheme.lavender.opacity(0.4),
                                        HomeDashboardPalette.accentOrange.opacity(0.32)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                AvatarGlyphView(
                    emoji: ChildModel.sanitizeAvatarEmoji(viewModel.selectedEmoji),
                    size: 30,
                    color: HomeDashboardPalette.nightMid
                )
            }
            .fixedSize()

            Text(addChildPreviewShowsName ? addChildPreviewNameTrimmed : "İsim yazıldığında burada görünür")
                .font(
                    .system(
                        size: addChildPreviewShowsName ? 17 : 15,
                        weight: addChildPreviewShowsName ? .bold : .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    addChildPreviewShowsName
                        ? HomeDashboardPalette.ink
                        : HomeDashboardPalette.muted.opacity(0.7)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.1), lineWidth: 1)
        )
    }

    private func addChildEmojiCell(emoji: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AvatarGlyphView(emoji: emoji, size: 22, color: HomeDashboardPalette.nightMid)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            isSelected
                                ? LumaTheme.lavender.opacity(0.16)
                                : HomeDashboardPalette.creamDeep.opacity(0.55)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(
                            isSelected ? LumaTheme.lavender : HomeDashboardPalette.muted.opacity(0.1),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func addChildSectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.07), lineWidth: 1)
        )
    }

    private func addChildTagInputRow(
        placeholder: String,
        text: Binding<String>,
        focus: AddChildField,
        accent: Color,
        onAdd: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
                .submitLabel(.done)
                .focused($focusedField, equals: focus)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(HomeDashboardPalette.creamDeep.opacity(0.55))
                )
                .contentShape(Rectangle())
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var submitButton: some View {
        let canSubmit = !viewModel.newChildName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Button {
            Task {
                let success = await viewModel.addChild(
                    interests: viewModel.interests,
                    fears: viewModel.fears
                )
                if success { isShowing = false }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Profili oluştur")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                LumaTheme.lavender,
                                HomeDashboardPalette.nightMid.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: LumaTheme.lavender.opacity(0.28), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || viewModel.isLoading)
        .opacity(canSubmit && !viewModel.isLoading ? 1 : 0.55)
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
                            Text("Çocuğun adı")
                                .font(.headline)
                                .foregroundColor(.black)
                            TextField("Örn: Elif", text: $viewModel.newChildName)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            Text("Masallarda ve profilde bu isim görünür.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avatar Emoji").font(.headline).foregroundColor(.black)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.availableEmojis, id: \.self) { emoji in
                                        let isSelected = viewModel.selectedEmoji == emoji
                                        AvatarGlyphView(emoji: emoji, size: 28, color: HomeDashboardPalette.nightMid)
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

                        if let err = viewModel.errorMessage, !err.isEmpty {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                        }
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

    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 4) {
                            Text(item)
                                .font(.caption)
                                .bold()
                                .lineLimit(1)
                            Button {
                                tags.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(color.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Kaldır")
                        }
                        .padding(.leading, 12)
                        .padding(.trailing, 8)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
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
