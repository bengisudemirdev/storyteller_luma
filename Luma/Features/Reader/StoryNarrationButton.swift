import SwiftUI

/// Masal seslendirmesini `NarrationPlaybackCenter` üzerinden başlatır; mini panel kontrolü orada.
struct StoryNarrationButton: View {
    let text: String
    var displayTitle: String = "Seslendirme"
    var classicTaleCacheId: String? = nil
    /// Okuyucu üst çubuğu ile uyumlu turuncu / krem tonları.
    var readerChrome: Bool = false

    @ObservedObject private var playback = NarrationPlaybackCenter.shared

    var body: some View {
        Button {
            playback.toggleOrStart(text: text, displayTitle: displayTitle, classicTaleCacheId: classicTaleCacheId)
        } label: {
            HStack(spacing: 6) {
                if playback.isLoading && playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId) {
                    ProgressView()
                        .scaleEffect(0.85)
                        .tint(readerChrome ? HomeDashboardPalette.accentOrange : LumaTheme.text)
                } else {
                    Image(systemName: toolbarIconName)
                }
                Text(toolbarLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
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
    }

    private var toolbarLabel: String {
        let same = playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId)
        if playback.isLoading && same { return "Hazırlanıyor" }
        if same && playback.isSessionActive && !playback.isLoading {
            return playback.transportShowsPause ? "Duraklat" : "Sürdür"
        }
        return "Seslendir"
    }

    private var toolbarIconName: String {
        let same = playback.isSameSession(text: text, classicTaleCacheId: classicTaleCacheId)
        if same && playback.isSessionActive && !playback.isLoading {
            return playback.transportShowsPause ? "pause.circle.fill" : "play.circle.fill"
        }
        return "speaker.wave.2.fill"
    }
}
