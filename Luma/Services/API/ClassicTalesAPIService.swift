import Foundation

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

private struct ClassicTaleAPIModel: Decodable {
    let id: String?
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

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case title
        case name
        case tag
        case teaser
        case summary
        case excerpt
        case fullStory = "fullStory"
        case full_story
        case content
        case story
        case attribution
        case source
        case coverTemplate = "coverTemplate"
        case cover_template
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

        let resolvedID = [id, slug, resolvedTitle.lowercased().replacingOccurrences(of: " ", with: "-")]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? UUID().uuidString.lowercased()

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

        return ClassicTaleItem(
            id: resolvedID,
            title: resolvedTitle,
            tag: resolvedTag,
            coverTemplate: coverTemplate,
            teaser: resolvedTeaser,
            fullStory: resolvedStory,
            attribution: resolvedAttribution
        )
    }

    private static func parseCoverTemplate(_ rawValue: String?) -> StoryCoverTemplateType? {
        guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty else { return nil }
        return StoryCoverTemplateType(rawValue: raw)
    }
}

enum ClassicTalesAPIService {
    private static let client = APIClient.shared

    static func fetchClassicTales(limit: Int = 30) async throws -> [ClassicTaleItem] {
        let templates: [StoryCoverTemplateType] = [.forest, .castle, .sleep, .friendship, .space, .ocean]
        let primaryEndpoint = APIEndpoint(
            path: "/v1/classic-tales",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
        let secondaryEndpoint = APIEndpoint(
            path: "/v1/stories/classics",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
        )

        let data = try await requestClassicList(primary: primaryEndpoint, fallback: secondaryEndpoint)
        let mapped = data.resolvedItems.enumerated().compactMap { index, item in
            item.toDomainModel(fallbackTemplate: templates[index % templates.count])
        }

        var seen = Set<String>()
        return mapped.filter { seen.insert($0.id).inserted }
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
}
