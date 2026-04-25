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
    @State private var showLimitAlert = false
    @State private var isCheckingSubscription = false

    var body: some View {
        Button {
            Task {
                isCheckingSubscription = true
                await SubscriptionManager.shared.refreshPlanFromServer()
                guard SubscriptionManager.shared.canStartNarration() else {
                    showLimitAlert = true
                    isCheckingSubscription = false
                    return
                }
                isCheckingSubscription = false
                playback.toggleOrStart(
                    text: text,
                    displayTitle: displayTitle,
                    classicTaleCacheId: classicTaleCacheId,
                    storyId: storyId,
                    storyAudioURL: storyAudioURL
                )
            }
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                if isCheckingSubscription ||
                    (playback.isLoading && playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId, storyId: storyId)) {
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
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCheckingSubscription)
        .alert("Seslendirme hakkı", isPresented: $showLimitAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(narrationLimitMessage)
        }
    }

    private var toolbarLabel: String {
        let same = playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId, storyId: storyId)
        if playback.isLoading && same { return "Hazırlanıyor" }
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
        switch SubscriptionManager.shared.plan {
        case .premium:
            return "Premium planda haftalık 5 seslendirme hakkı bulunur. Bu haftaki hakkın doldu."
        case .free:
            return "Free planda seslendirme bir kerelik deneme hakkı olarak sunulur."
        }
    }
}
