import SwiftUI

/// Profil → geri bildirim: mesaj uygulama içinden sunucuya gönderilir (alıcı adresi gösterilmez, e-posta uygulaması açılmaz).
struct ProfileFeedbackSheet: View {
    private static let maxLength = 2000

    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var phase: Phase = .editing
    @FocusState private var messageFocused: Bool

    private enum Phase: Equatable {
        case editing
        case sending
        case sent
        case failed(String)
    }

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        trimmedMessage.count >= 3 && phase != .sending
    }

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                if phase == .sent {
                    sentView
                } else {
                    formView
                }
            }
        }
    }

    private var formView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Görüş, öneri ya da karşılaştığın bir sorunu yaz. Mesajın doğrudan ekibimize ulaşır.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .trailing, spacing: 6) {
                    TextField("", text: $message, prompt: lumaPrompt("Geri bildirimin…"), axis: .vertical)
                        .lumaInputText()
                        .lineLimit(5...12)
                        .focused($messageFocused)
                        .disabled(phase == .sending)
                        .lumaInputBox(focused: messageFocused, multiline: true)
                        .onChange(of: message) { _, newValue in
                            if newValue.count > Self.maxLength {
                                message = String(newValue.prefix(Self.maxLength))
                            }
                            if case .failed = phase { phase = .editing }
                        }

                    Text("\(message.count) / \(Self.maxLength)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted.opacity(0.8))
                }

                if case .failed(let text) = phase {
                    Text(text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.red.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: { Task { await send() } }) {
                    HStack(spacing: 8) {
                        if phase == .sending {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(phase == .sending ? "Gönderiliyor…" : "Gönder")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                            .shadow(color: HomeDashboardPalette.accentOrange.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .opacity(canSend ? 1 : 0.5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var sentView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
            Text("Teşekkürler!")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
            Text("Geri bildirimin bize ulaştı. Bizimle paylaştığın için teşekkür ederiz.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Kapat") { dismiss() }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.accentOrange)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Geri bildirim")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(HomeDashboardPalette.ink)
                Text("Bize yaz")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            }
            Spacer(minLength: 12)
            Button {
                dismiss()
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

    private func send() async {
        guard canSend else { return }
        messageFocused = false
        phase = .sending
        do {
            try await FeedbackAPIService.send(message: trimmedMessage)
            phase = .sent
        } catch let error as APIClientError {
            if case .server(let code, _) = error, code.uppercased() == "RATE_LIMITED" {
                phase = .failed("Kısa sürede çok fazla mesaj gönderdin. Lütfen biraz sonra tekrar dene.")
            } else {
                phase = .failed(error.errorDescription ?? "Mesaj gönderilemedi. Lütfen tekrar dene.")
            }
        } catch {
            phase = .failed("Mesaj gönderilemedi. Bağlantını kontrol edip tekrar dene.")
        }
    }
}

#Preview {
    ProfileFeedbackSheet()
}
