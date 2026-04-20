import SwiftUI

/// Seslendirme başlayınca alt kısımda gösterilen taşıma çubuğu (duraklat / oynat / geri / dur).
struct NarrationMiniPlayerView: View {
    @ObservedObject private var playback = NarrationPlaybackCenter.shared

    var body: some View {
        if playback.isPanelVisible {
            VStack(spacing: 6) {
                Capsule()
                    .fill(HomeDashboardPalette.muted.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 2)
                    .accessibilityLabel(String(localized: "Konumu değiştirmek için sürükle"))
                    .accessibilityAddTraits(.allowsDirectInteraction)

                HStack(spacing: 14) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(HomeDashboardPalette.accentOrange.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(playback.displayTitle)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(HomeDashboardPalette.ink)
                            .lineLimit(1)
                        if playback.isLoading {
                            Text("Hazırlanıyor…")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        } else {
                            Text(playback.transportShowsPause ? "Çalıyor" : "Duraklatıldı")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(HomeDashboardPalette.sectionCaption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 18) {
                        Button {
                            playback.rewindFifteenSeconds()
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(HomeDashboardPalette.ink)
                        }
                        .buttonStyle(.plain)
                        .disabled(playback.isLoading)

                        Button {
                            playback.togglePauseResume()
                        } label: {
                            Image(systemName: playback.transportShowsPause ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(HomeDashboardPalette.accentOrange)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .disabled(playback.isLoading)

                        Button {
                            playback.stopEverything()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(HomeDashboardPalette.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(HomeDashboardPalette.dashboardCanvas)
                        .shadow(color: HomeDashboardPalette.cardElevatedShadow, radius: 12, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(HomeDashboardPalette.cardEdgeStroke, lineWidth: 1)
                )
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: playback.isPanelVisible)
        }
    }
}
