import SwiftUI

/// Kayıt akışı 2/2: çocuk profili **zorunlu**; API başarılı olana kadar `luma_registration_requires_child_setup` kalkmaz.
struct RegistrationChildSetupView: View {
    let onCompleted: () -> Void

    @State private var childName = ""
    @State private var childAgeText = ""
    @State private var avatarEmoji = ChildModel.defaultAvatarEmoji
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let avatarChoices = ChildModel.supportedAvatarEmojis
    private let emojiColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private var trimmedName: String {
        childName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedAge: Int? {
        Int(childAgeText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var isAgeValid: Bool {
        guard let a = parsedAge else { return false }
        return (1...17).contains(a)
    }

    private var canSubmit: Bool {
        !trimmedName.isEmpty && isAgeValid
    }

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    registrationStepChip(step: 2, title: "Çocuk profili — zorunlu")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kaydı tamamla")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(HomeDashboardPalette.ink)
                        Text("Masalları kişiselleştirmek için bir çocuk eklemen gerekir.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LumaTheme.lavender)
                        Text("Bu adım atlanamaz. Profil kaydedilmeden hesabın tamamlanmaz ve ana ekrana geçemezsin.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LumaTheme.lavender.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(LumaTheme.lavender.opacity(0.22), lineWidth: 1)
                    )

                    previewRow

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Çocuğun adı", systemImage: "sparkles")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.accentOrange)
                            TextField("", text: $childName, prompt: lumaPrompt("Örn: Elif"))
                                .lumaInputText()
                                .textInputAutocapitalization(.words)
                                .lumaInputBox()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Yaş", systemImage: "birthday.cake.fill")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.accentOrange)
                            TextField("", text: $childAgeText, prompt: lumaPrompt("1–17 arası"))
                                .keyboardType(.numberPad)
                                .lumaInputText()
                                .lumaInputBox()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Avatar")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.accentOrange)
                            LazyVGrid(columns: emojiColumns, spacing: 8) {
                                ForEach(avatarChoices, id: \.self) { emoji in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            avatarEmoji = emoji
                                        }
                                    } label: {
                                        AvatarGlyphView(emoji: emoji, size: 24, color: HomeDashboardPalette.nightMid)
                                            .frame(maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fit)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(
                                                        avatarEmoji == emoji
                                                            ? LumaTheme.lavender.opacity(0.2)
                                                            : HomeDashboardPalette.creamDeep.opacity(0.5)
                                                    )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        avatarEmoji == emoji
                                                            ? LumaTheme.lavender
                                                            : HomeDashboardPalette.muted.opacity(0.1),
                                                        lineWidth: avatarEmoji == emoji ? 2 : 0.5
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.red.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.red.opacity(0.08))
                                )
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .fill(HomeDashboardPalette.cardSurface)
                            .shadow(color: HomeDashboardPalette.cardShadow, radius: 14, x: 0, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeDashboardMetrics.cardCornerRadius, style: .continuous)
                            .stroke(HomeDashboardPalette.accentOrange.opacity(0.1), lineWidth: 1)
                    )

                    Button {
                        Task { await completeRegistration() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Kaydı tamamla")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            HomeDashboardPalette.accentOrange,
                                            LumaTheme.lavender.opacity(0.95)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: HomeDashboardPalette.accentOrange.opacity(0.35), radius: 14, x: 0, y: 7)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving || !canSubmit)
                    .opacity(canSubmit && !isSaving ? 1 : 0.45)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, HomeDashboardMetrics.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var previewRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HomeDashboardPalette.accentOrangeSoft.opacity(0.55),
                                HomeDashboardPalette.accentOrange.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 36
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        LumaTheme.lavender.opacity(0.45),
                                        HomeDashboardPalette.accentOrange.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                AvatarGlyphView(emoji: avatarEmoji, size: 32, color: HomeDashboardPalette.nightMid)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Önizleme")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(trimmedName.isEmpty ? "İsim burada görünür" : trimmedName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(trimmedName.isEmpty ? HomeDashboardPalette.muted.opacity(0.65) : HomeDashboardPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if isAgeValid, let a = parsedAge {
                    Text("\(a) yaş")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(HomeDashboardPalette.accentOrange.opacity(0.1), lineWidth: 1)
        )
    }

    private func registrationStepChip(step: Int, title: String) -> some View {
        HStack(spacing: 8) {
            Text("\(step)/2")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(HomeDashboardPalette.accentOrange)
                )
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .tracking(0.45)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private func completeRegistration() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        guard !trimmedName.isEmpty else {
            errorMessage = "Lütfen çocuğunuzun adını girin."
            return
        }

        guard let age = parsedAge, (1...17).contains(age) else {
            errorMessage = "Lütfen 1–17 arasında bir yaş girin."
            return
        }

        errorMessage = nil
        do {
            _ = try await ChildrenAPIService.createChild(
                name: trimmedName,
                age: age,
                avatarEmoji: avatarEmoji,
                interests: nil,
                fears: nil
            )
            UserDefaults.standard.set(false, forKey: "luma_registration_requires_child_setup")
            UserDefaults.standard.set(true, forKey: LumaUserDefaultsKeys.showPostRegistrationPaywallOnce)
            onCompleted()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                NotificationCenter.default.post(name: .lumaPresentPostRegistrationPaywall, object: nil)
            }
        } catch {
            errorMessage = error.userFacingTurkishMessage
        }
    }
}

#Preview {
    RegistrationChildSetupView(onCompleted: {})
}
