import SwiftUI
import UIKit

/// Profil → geri bildirim: metni `mailto:` ile sistem e-posta uygulamasına aktarır.
struct ProfileFeedbackSheet: View {
    let recipientEmail: String
    let userEmail: String

    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var showMailUnavailable = false

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Düşüncelerini yaz; e-posta uygulaması açıldığında mesajın hazır olur. Gönder tuşuna orada basarsın.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        TextField("Geri bildirimin…", text: $message, axis: .vertical)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink)
                            .lineLimit(5...12)
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(HomeDashboardPalette.cardSurface)
                                    .shadow(color: HomeDashboardPalette.cardShadow, radius: 8, x: 0, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(HomeDashboardPalette.accentOrange.opacity(0.12), lineWidth: 1)
                            )

                        Text("Alıcı: \(recipientEmail)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.muted)

                        Button(action: openMailComposer) {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.open.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("E-posta uygulamasında aç")
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
                        .disabled(trimmedMessage.isEmpty)
                        .opacity(trimmedMessage.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .alert("E-posta açılamadı", isPresented: $showMailUnavailable) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bu cihazda yapılandırılmış bir e-posta hesabı yok veya mail bağlantıları desteklenmiyor. Adresi kopyalayıp elle yazabilirsin: \(recipientEmail)")
        }
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

    private func openMailComposer() {
        let subject = "Olia — Geri bildirim"
        var body = trimmedMessage
        if !userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body += "\n\n—\nHesap: \(userEmail)"
        }

        guard let url = Self.mailtoURL(to: recipientEmail, subject: subject, body: body) else {
            showMailUnavailable = true
            return
        }

        UIApplication.shared.open(url) { success in
            if success {
                dismiss()
            } else {
                showMailUnavailable = true
            }
        }
    }

    private static func mailtoURL(to: String, subject: String, body: String) -> URL? {
        guard var components = URLComponents(string: "mailto:\(to)") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}

#Preview {
    ProfileFeedbackSheet(recipientEmail: "olia.destek@gmail.com", userEmail: "ebeveyn@ornek.com")
}
