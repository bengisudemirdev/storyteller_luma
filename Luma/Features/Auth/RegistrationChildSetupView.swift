import SwiftUI

struct RegistrationChildSetupView: View {
    let onCompleted: () -> Void

    @State private var childName = ""
    @State private var childAgeText = ""
    @State private var avatarEmoji = "🦊"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [LumaTheme.bg, LumaTheme.lightYellow, LumaTheme.softBlue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    Text("Kaydı Tamamla")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(LumaTheme.text)
                    Text("2/2 • Çocuk profili")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LumaTheme.lavender)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.8))
                        )
                    Text("Çocuğunuzu eklediğinizde hesabınız tamamlanır.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(LumaTheme.secondaryText)
                }

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Text(avatarEmoji)
                            .font(.system(size: 30))
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        TextField("Çocuğun adı", text: $childName)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(LumaTheme.text)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 12) {
                        Image(systemName: "birthday.cake.fill")
                            .foregroundStyle(LumaTheme.lavender)
                            .frame(width: 24)
                        TextField("Yaş", text: $childAgeText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(LumaTheme.text)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 10) {
                        ForEach(["🦊", "🦄", "🐻", "🐯", "🦁"], id: \.self) { emoji in
                            Button {
                                avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(avatarEmoji == emoji ? LumaTheme.lavender.opacity(0.2) : Color.white.opacity(0.75))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(22)
                .background(Color.white.opacity(0.76))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Button {
                    Task { await completeRegistration() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 6)
                        }
                        Text(isSaving ? "Kaydediliyor..." : "Kaydı Tamamla")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [LumaTheme.lavender, LumaTheme.lavender.opacity(0.82)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: LumaTheme.lavender.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .disabled(isSaving)

                Spacer(minLength: 24)
            }
        }
    }

    private func completeRegistration() async {
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Lütfen çocuğunuzun adını girin."
            return
        }

        guard let age = Int(childAgeText), (1...17).contains(age) else {
            errorMessage = "Lütfen 1-17 arasında bir yaş girin."
            return
        }

        isSaving = true
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
            onCompleted()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    RegistrationChildSetupView(onCompleted: {})
}
