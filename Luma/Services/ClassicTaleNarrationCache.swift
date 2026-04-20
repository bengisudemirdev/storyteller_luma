import Foundation

/// Klasik masal ElevenLabs seslendirmelerini `Caches` altında saklar (ses veya agent değişince alt klasör ayrılır).
enum ClassicTaleNarrationCache {
    private static let rootFolderName = "luma-classic-narration"
    private static let cacheVersion = "v1"

    /// Ses kimliği; `.env` içindeki tercih veya agent ile önbellek ayrımı.
    static func voiceFingerprint() -> String {
        if let v = AppConfig.elevenLabsPreferredVoiceId, !v.isEmpty {
            return "voice_\(sanitizePathSegment(v))"
        }
        let agent = Secrets.elevenLabsAgentId.trimmingCharacters(in: .whitespacesAndNewlines)
        return "agent_\(sanitizePathSegment(agent))"
    }

    private static func sanitizePathSegment(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
    }

    private static func rootDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = base
            .appendingPathComponent(rootFolderName, isDirectory: true)
            .appendingPathComponent(cacheVersion, isDirectory: true)
            .appendingPathComponent(voiceFingerprint(), isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func taleDirectory(taleId: String) throws -> URL {
        try rootDirectory().appendingPathComponent(sanitizePathSegment(taleId), isDirectory: true)
    }

    private static let audioFilenameSuffixes = ["mp3", "m4a", "aac", "mp4", "caf", "wav"]

    /// Önbellekte sıralı ses parçaları varsa döner (ElevenLabs MP3 veya API’den indirilen `.m4a` vb.).
    static func cachedChunkURLs(taleId: String) -> [URL]? {
        guard let dir = try? taleDirectory(taleId: taleId),
              FileManager.default.fileExists(atPath: dir.path) else { return nil }
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return nil }
        let audioNames = names.filter { name in
            let ext = (name as NSString).pathExtension.lowercased()
            return audioFilenameSuffixes.contains(ext)
        }
        guard !audioNames.isEmpty else { return nil }
        let sorted = audioNames.sorted { a, b in
            numericStem(a) < numericStem(b)
        }
        return sorted.map { dir.appendingPathComponent($0) }
    }

    private static func numericStem(_ filename: String) -> Int {
        let base = (filename as NSString).deletingPathExtension
        return Int(base) ?? 0
    }

    /// API’den indirilen tek dosyayı önbelleğe yazar (`0.m4a` vb.).
    static func replaceCacheWithRemoteDownloadedFile(at tempURL: URL, taleId: String) throws -> [URL] {
        let dir = try taleDirectory(taleId: taleId)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let ext = tempURL.pathExtension.isEmpty ? "m4a" : tempURL.pathExtension
        let dst = dir.appendingPathComponent("0.\(ext)")
        if FileManager.default.fileExists(atPath: dst.path) {
            try FileManager.default.removeItem(at: dst)
        }
        try FileManager.default.copyItem(at: tempURL, to: dst)
        return [dst]
    }

    /// Geçici TTS çıktısını kalıcı önbelleğe kopyalar; dönen URL’ler oynatma için (oynatıcı bunları silmez).
    static func replaceCache(withTempChunks tempURLs: [URL], taleId: String) throws -> [URL] {
        let dir = try taleDirectory(taleId: taleId)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var permanent: [URL] = []
        for (index, tmp) in tempURLs.enumerated() {
            let dst = dir.appendingPathComponent("\(index).mp3")
            if FileManager.default.fileExists(atPath: dst.path) {
                try FileManager.default.removeItem(at: dst)
            }
            try FileManager.default.copyItem(at: tmp, to: dst)
            permanent.append(dst)
        }
        for tmp in tempURLs {
            try? FileManager.default.removeItem(at: tmp)
        }
        return permanent
    }
}
