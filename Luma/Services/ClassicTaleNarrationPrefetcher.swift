import Foundation

/// Tüm klasik masallar için ElevenLabs sesini arka planda indirip cihaz önbelleğine yazar.
enum ClassicTaleNarrationPrefetcher {
    private static let lock = NSLock()
    private static var didScheduleSession = false

    /// `OliaApp.init` içinde çağrılır: oturumda bir kez, kullanıcı aksiyonu olmadan arka planda.
    static func schedulePrefetchIfNeeded() {
        guard AppConfig.isElevenLabsNarrationConfigured else { return }
        lock.lock()
        defer { lock.unlock() }
        guard !didScheduleSession else { return }
        didScheduleSession = true

        Task.detached(priority: .utility) {
            await prefetchMissingTales()
        }
    }

    private static func prefetchMissingTales() async {
        let apiKey = Secrets.elevenLabsAPIKey
        let agentId = Secrets.elevenLabsAgentId

        for tale in ClassicTaleItem.bundledTales {
            if Task.isCancelled { break }
            if let existing = ClassicTaleNarrationCache.cachedChunkURLs(taleId: tale.id), !existing.isEmpty {
                continue
            }

            let text = tale.narrationText
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            do {
                let (voiceId, modelId, voiceSettings) = try await ElevenLabsNarrationService.resolveVoiceModelForNarration(
                    apiKey: apiKey,
                    agentId: agentId,
                    preferredVoiceId: AppConfig.elevenLabsPreferredVoiceId
                )
                let tempURLs = try await ElevenLabsNarrationService.synthesizeToTempFiles(
                    text: text,
                    apiKey: apiKey,
                    voiceId: voiceId,
                    modelId: modelId,
                    voiceSettings: voiceSettings
                )
                _ = try ClassicTaleNarrationCache.replaceCache(withTempChunks: tempURLs, taleId: tale.id)
            } catch {
                AppLogger.error("classic.narration.prefetch.failed", [
                    "taleId": tale.id,
                    "error": String(describing: error)
                ])
            }
        }
    }
}
