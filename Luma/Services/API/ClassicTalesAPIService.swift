import Foundation

private struct ClassicTaleDetailDataDTO: Decodable {
    let tale: ClassicTaleAPIModel?
}

private struct ClassicTalesListDataDTO: Decodable {
    let tales: [ClassicTaleAPIModel]?
    let classicTales: [ClassicTaleAPIModel]?
    let classics: [ClassicTaleAPIModel]?
    let items: [ClassicTaleAPIModel]?

    enum CodingKeys: String, CodingKey {
        case tales
        case classicTales = "classic_tales"
        case classics
        case items
    }

    var resolvedItems: [ClassicTaleAPIModel] {
        tales ?? classicTales ?? classics ?? items ?? []
    }
}

/// `GET /v1/classic-tales` → `data.tales[]` (OpenAPI ile uyumlu alanlar).
private struct ClassicTaleAPIModel: Decodable {
    let id: String?
    let taleId: String?
    let tale_id: String?
    let slug: String?
    let title: String?
    let name: String?
    let tag: String?
    let teaser: String?
    let summary: String?
    let excerpt: String?
    let fullStory: String?
    let full_story: String?
    let content: String?
    let story: String?
    let attribution: String?
    let source: String?
    let coverTemplate: String?
    let cover_template: String?
    let coverImageUrl: String?
    let cover_image_url: String?
    let audioUrl: String?
    let audio_url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case taleId
        case tale_id
        case slug
        case title
        case name
        case tag
        case teaser
        case summary
        case excerpt
        case fullStory
        case full_story
        case content
        case story
        case attribution
        case source
        case coverTemplate
        case cover_template
        case coverImageUrl
        case cover_image_url
        case audioUrl
        case audio_url
    }

    func toDomainModel(fallbackTemplate: StoryCoverTemplateType) -> ClassicTaleItem? {
        let resolvedTitle = [title, name]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        guard !resolvedTitle.isEmpty else { return nil }

        let resolvedStory = [fullStory, full_story, content, story, excerpt, summary]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        guard !resolvedStory.isEmpty else { return nil }

        let slugCandidate = [taleId, tale_id, slug]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        let serverId = id?.trimmingCharacters(in: .whitespacesAndNewlines)
        let serverIdNonEmpty = (serverId?.isEmpty == false) ? serverId : nil

        let fallbackSlug = resolvedTitle.lowercased().replacingOccurrences(of: " ", with: "-")
        let stableId: String
        if let slugCandidate, !slugCandidate.isEmpty {
            stableId = slugCandidate
        } else if let serverIdNonEmpty, !serverIdNonEmpty.isEmpty {
            stableId = serverIdNonEmpty
        } else {
            stableId = fallbackSlug
        }

        let resolvedTeaser = [teaser, summary, excerpt]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? String(resolvedStory.prefix(100))

        let coverTemplate = Self.parseCoverTemplate(coverTemplate ?? cover_template) ?? fallbackTemplate
        let resolvedTag = (tag?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? tag!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "Dünya Klasiği"

        let resolvedAttribution = [attribution, source]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Kaynak: Backend klasik masal servisi"

        let coverString = [coverImageUrl, cover_image_url]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        let coverURL = Self.parseCoverURL(coverString)

        let audioString = [audioUrl, audio_url]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        let audioURL = Self.parseCoverURL(audioString)

        return ClassicTaleItem(
            id: stableId,
            title: resolvedTitle,
            tag: resolvedTag,
            coverTemplate: coverTemplate,
            teaser: resolvedTeaser,
            fullStory: resolvedStory,
            attribution: resolvedAttribution,
            audioURL: audioURL,
            coverImageURL: coverURL,
            apiRecordId: serverIdNonEmpty
        )
    }

    private static func parseCoverTemplate(_ rawValue: String?) -> StoryCoverTemplateType? {
        guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty else { return nil }
        return StoryCoverTemplateType(rawValue: raw)
    }

    private static func parseCoverURL(_ rawValue: String?) -> URL? {
        guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }

        if value.hasPrefix("//") {
            return URL(string: "https:\(value)")
        }

        if let url = URL(string: value), url.scheme != nil {
            return url
        }

        if value.hasPrefix("/") {
            let base = AppConfig.backendBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return URL(string: "\(base)\(value)")
        }

        return nil
    }
}

private struct ClassicTaleAudioUploadDataDTO: Decodable {
    let taleId: String?
    let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case taleId
        case tale_id
        case audioUrl
        case audio_url
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        taleId = try c.decodeIfPresent(String.self, forKey: .taleId) ?? c.decodeIfPresent(String.self, forKey: .tale_id)
        audioUrl = try c.decodeIfPresent(String.self, forKey: .audioUrl) ?? c.decodeIfPresent(String.self, forKey: .audio_url)
    }

    func resolvedAudioURLString() -> String? {
        let s = audioUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (s?.isEmpty == false) ? s : nil
    }
}

enum ClassicTalesAPIService {
    private static let client = APIClient.shared

    /// OpenAPI: parametre yok; yanıt `{ success, data: { tales } } }` (`APIClient` `data` içeriğini döner).
    static func fetchClassicTales() async throws -> [ClassicTaleItem] {
        let templates: [StoryCoverTemplateType] = [.forest, .castle, .sleep, .friendship, .space, .ocean]
        let primaryEndpoint = APIEndpoint(
            path: "/v1/classic-tales",
            method: .get,
            queryItems: []
        )
        let secondaryEndpoint = APIEndpoint(
            path: "/v1/stories/classics",
            method: .get,
            queryItems: []
        )

        let data = try await requestClassicList(primary: primaryEndpoint, fallback: secondaryEndpoint)
        let mapped = data.resolvedItems.enumerated().compactMap { index, item in
            item.toDomainModel(fallbackTemplate: templates[index % templates.count])
        }
        let normalized = normalizeWithBundledFallback(mapped)

        var seen = Set<String>()
        return normalized.filter { seen.insert($0.id).inserted }
    }

    /// `GET /v1/classic-tales/{taleId}` → `data.tale` (ör. `audioUrl` için).
    static func fetchClassicTaleDetail(taleId: String) async throws -> ClassicTaleItem? {
        let pathSegment = taleId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? taleId
        let endpoint = APIEndpoint(path: "/v1/classic-tales/\(pathSegment)", method: .get)
        let data: ClassicTaleDetailDataDTO = try await client.request(endpoint)
        guard let model = data.tale else { return nil }
        guard let item = model.toDomainModel(fallbackTemplate: .forest) else { return nil }
        return normalizeWithBundledFallback([item]).first
    }

    private static func requestClassicList(
        primary: APIEndpoint,
        fallback: APIEndpoint
    ) async throws -> ClassicTalesListDataDTO {
        do {
            let data: ClassicTalesListDataDTO = try await client.request(primary)
            if !data.resolvedItems.isEmpty {
                return data
            }
        } catch {
            AppLogger.warning("classic_tales.fetch.primary_failed", [
                "path": primary.path,
                "error": String(describing: type(of: error))
            ])
        }

        return try await client.request(fallback)
    }

    /// Sunucu `id` alanını UUID döndürdüğünde, yerel slug'a düşerek kapak yolu (`classic-tales/{taleId}/cover.png`) korunur.
    private static func normalizeWithBundledFallback(_ tales: [ClassicTaleItem]) -> [ClassicTaleItem] {
        let bundledByTitle = Dictionary(uniqueKeysWithValues: ClassicTaleItem.bundledTales.map {
            (normalizeTitle($0.title), $0)
        })

        return tales.map { tale in
            let normalizedTitle = normalizeTitle(tale.title)
            guard let bundled = bundledByTitle[normalizedTitle] else { return tale }
            let stableId = looksLikeUUID(tale.id) ? bundled.id : tale.id

            return ClassicTaleItem(
                id: stableId,
                title: tale.title,
                tag: tale.tag,
                coverTemplate: tale.coverTemplate,
                teaser: tale.teaser,
                fullStory: tale.fullStory,
                attribution: tale.attribution,
                audioURL: tale.audioURL,
                coverImageURL: tale.coverImageURL,
                apiRecordId: tale.apiRecordId
            )
        }
    }

    private static func looksLikeUUID(_ rawValue: String) -> Bool {
        UUID(uuidString: rawValue) != nil
    }

    private static func normalizeTitle(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }

    // MARK: - Önbellekteki sesi API’ye yükleme (admin JWT; `POST /v1/classic-tales/{taleId}/audio`, `multipart/form-data` alanı `file`)

    enum NarrationUploadError: LocalizedError {
        case noCachedAudio

        var errorDescription: String? {
            switch self {
            case .noCachedAudio:
                return "Bu masal için önbellekte ses dosyası yok."
            }
        }
    }

    /// Cihaz önbelleğindeki MP3 parçalarını tek dosyada birleştirip sunucuya yükler.
    static func uploadCachedNarrationAudio(taleId: String) async throws -> URL {
        let chunks = ClassicTaleNarrationCache.cachedChunkURLs(taleId: taleId) ?? []
        guard !chunks.isEmpty else { throw NarrationUploadError.noCachedAudio }

        let fileURL: URL
        let removeAfterUpload: Bool
        if chunks.count == 1 {
            fileURL = chunks[0]
            removeAfterUpload = false
        } else {
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("luma-classic-upload-\(UUID().uuidString).mp3")
            var merged = Data()
            for u in chunks {
                merged.append(try Data(contentsOf: u))
            }
            try merged.write(to: temp, options: .atomic)
            fileURL = temp
            removeAfterUpload = true
        }

        defer {
            if removeAfterUpload {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        let pathSegment = taleId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? taleId
        let endpoint = APIEndpoint(
            path: "/v1/classic-tales/\(pathSegment)/audio",
            method: .post,
            timeoutInterval: 300
        )
        let data: ClassicTaleAudioUploadDataDTO = try await client.uploadMultipart(endpoint, fileURL: fileURL)
        guard let raw = data.resolvedAudioURLString(), let url = URL(string: raw) else {
            throw APIClientError.decodingFailed
        }
        return url
    }

    /// `bundledTales` kimlikleri için önbellekte ses varsa sırayla yükler. Hata alan masallar atlanır, günlükte kaydedilir.
    static func uploadAllCachedBundledNarrationAudio() async -> [(taleId: String, Result<URL, Error>)] {
        var results: [(taleId: String, Result<URL, Error>)] = []
        for tale in ClassicTaleItem.bundledTales {
            guard !(ClassicTaleNarrationCache.cachedChunkURLs(taleId: tale.id) ?? []).isEmpty else {
                continue
            }
            do {
                let url = try await uploadCachedNarrationAudio(taleId: tale.id)
                results.append((tale.id, .success(url)))
            } catch {
                AppLogger.error("classic_tales.audio.upload.failed", [
                    "taleId": tale.id,
                    "error": String(describing: error)
                ])
                results.append((tale.id, .failure(error)))
            }
        }
        return results
    }
}
