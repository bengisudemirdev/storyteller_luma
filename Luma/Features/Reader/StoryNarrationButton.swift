import SwiftUI

/// Masal seslendirmesini `NarrationPlaybackCenter` üzerinden başlatır; mini panel kontrolü orada.
struct StoryNarrationButton: View {
    let text: String
    var displayTitle: String = "Seslendirme"
    var classicTaleCacheId: String? = nil
    /// Kayıtlı kullanıcı masalı için API ses kaydı kimliği.
    var storyId: UUID? = nil
    /// Sunucudaki hazır ses kaydı URL'si (`story.audio_url`) varsa doğrudan çalınır.
    var storyAudioURL: String? = nil
    /// Okuyucu üst çubuğu ile uyumlu turuncu / krem tonları.
    var readerChrome: Bool = false
    /// Dar yatay alanlarda yalnızca ikon göster.
    var compact: Bool = false

    @ObservedObject private var playback = NarrationPlaybackCenter.shared
    @StateObject private var narrationViewModel = NarrationViewModel()
    @State private var showLimitAlert = false

    var body: some View {
        Button {
            narrationViewModel.toggleOrStart(
                with: .init(
                    text: text,
                    displayTitle: displayTitle,
                    classicTaleCacheId: classicTaleCacheId,
                    storyId: storyId,
                    storyAudioURL: storyAudioURL
                ),
                playback: playback
            )
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                if playback.isLoading &&
                    playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId, storyId: storyId) {
                    ProgressView()
                        .scaleEffect(0.85)
                        .tint(readerChrome ? HomeDashboardPalette.accentOrange : LumaTheme.text)
                } else {
                    Image(systemName: toolbarIconName)
                }
                if !compact {
                    Text(toolbarLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, compact ? 9 : 10)
            .padding(.vertical, readerChrome ? 8 : 6)
            .background(
                readerChrome
                    ? HomeDashboardPalette.accentOrange.opacity(0.16)
                    : LumaTheme.softBlue.opacity(0.15)
            )
            .foregroundStyle(readerChrome ? HomeDashboardPalette.ink : LumaTheme.text)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .onReceive(playback.$lastErrorCode) { code in
            guard code == "INSUFFICIENT_CREDITS" else { return }
            if classicTaleCacheId != nil {
                narrationViewModel.infoMessage = "Klasik masal seslendirmeleri kredi harcamaz."
                showLimitAlert = true
                return
            }
            narrationViewModel.infoMessage = narrationLimitMessage
            narrationViewModel.showCreditStore = true
            showLimitAlert = false
        }
        .onReceive(playback.$lastErrorMessage) { message in
            guard let message, !message.isEmpty else { return }
            if playback.lastErrorCode == "INSUFFICIENT_CREDITS" {
                // yetersiz kredi için sheet açılacak; alert metni özel bırakılıyor
            } else {
                showLimitAlert = true
            }
        }
        .alert("Kredi bilgisi", isPresented: $showLimitAlert) {
            Button("Tamam", role: .cancel) {
                playback.clearErrorState()
            }
        } message: {
            Text(narrationViewModel.infoMessage ?? alertMessage)
        }
        .sheet(isPresented: $narrationViewModel.showCreditStore, onDismiss: {
            playback.clearErrorState()
        }) {
            PaywallView(
                source: .insufficientCredits(required: CreditCost.narration),
                onPurchaseCompleted: {
                    narrationViewModel.handlePurchaseCompletion(playback: playback)
                }
            )
        }
    }

    private var alertMessage: String {
        if playback.lastErrorCode == "INSUFFICIENT_CREDITS" {
            return narrationLimitMessage
        }
        return playback.lastErrorMessage ?? narrationLimitMessage
    }

    private var toolbarLabel: String {
        let same = playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId, storyId: storyId)
        if playback.isLoading && same {
            return storyId == nil ? "Hazırlanıyor" : "İşleniyor"
        }
        if same && playback.isSessionActive && !playback.isLoading {
            return playback.transportShowsPause ? "Duraklat" : "Sürdür"
        }
        return "Seslendir"
    }

    private var toolbarIconName: String {
        let same = playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId, storyId: storyId)
        if same && playback.isSessionActive && !playback.isLoading {
            return playback.transportShowsPause ? "pause.circle.fill" : "play.circle.fill"
        }
        return "speaker.wave.2.fill"
    }

    private var narrationLimitMessage: String {
        "Seslendirme için en az \(CreditCost.narration) kredi gerekiyor."
    }
}
