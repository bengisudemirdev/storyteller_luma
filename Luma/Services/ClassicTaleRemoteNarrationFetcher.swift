import Foundation

/// `ClassicTaleItem.audioURL` üzerinden sunucudaki ses dosyasını indirip `ClassicTaleNarrationCache` içine yazar.
enum ClassicTaleRemoteNarrationFetcher {
    private static let userDefaultsKeyPrefix = "luma_classic_remote_audio_url_"

    private static let downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config)
    }()

    /// Masal listesi geldikten sonra arka planda çağrılır; `audioUrl` yoksa atlanır.
    static func prefetchRemoteAudio(for tales: [ClassicTaleItem]) async {
        for tale in tales {
            guard let remote = tale.audioURL else { continue }

            let key = userDefaultsKeyPrefix + tale.id
            if UserDefaults.standard.string(forKey: key) == remote.absoluteString,
               ClassicTaleNarrationCache.cachedChunkURLs(taleId: tale.id) != nil {
                continue
            }

            do {
                let tempURL = try await downloadToTemporaryFile(from: remote)
                defer { try? FileManager.default.removeItem(at: tempURL) }
                _ = try ClassicTaleNarrationCache.replaceCacheWithRemoteDownloadedFile(at: tempURL, taleId: tale.id)
                UserDefaults.standard.set(remote.absoluteString, forKey: key)
            } catch {
                AppLogger.error("classic_tales.remote_audio.prefetch_failed", [
                    "taleId": tale.id,
                    "error": String(describing: error)
                ])
            }
        }
    }

    private static func downloadToTemporaryFile(from remoteURL: URL) async throws -> URL {
        let (tempURL, response) = try await downloadSession.download(from: remoteURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }
        return tempURL
    }
}
