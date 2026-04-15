import Foundation

/// POST /v1/stories/generate — yalnızca hikâyeye özel alanlar; çocuk profili sunucuda okunur.
struct StoryGenerateRequestDTO: Encodable {
    let childId: UUID
    let theme: String
    let language: String?
    let extraContext: String?
    let selectedInterests: [String]?
    let storyGoal: String?
}

struct StoryGenerateDataDTO: Decodable {
    let story: StoryModel
}

struct StoryListDataDTO: Decodable {
    let stories: [StoryModel]
}

struct StoryDetailDataDTO: Decodable {
    let story: StoryModel
}

enum StoryAPIService {
    private static let client = APIClient.shared

    static func generateStory(
        childId: UUID,
        theme: String,
        language: String? = nil,
        extraContext: String? = nil,
        selectedInterests: [String]? = nil,
        storyGoal: String? = nil
    ) async throws -> StoryModel {
        AppLogger.info("stories.generate.request_sent", [
            "childId": childId.uuidString,
            "theme": theme,
            "language": language ?? "default",
            "hasExtraContext": extraContext == nil || extraContext?.isEmpty == true ? "false" : "true",
            "extraContextLength": "\(extraContext?.count ?? 0)",
            "selectedInterestsCount": "\(selectedInterests?.count ?? 0)",
            "hasStoryGoal": storyGoal == nil || storyGoal?.isEmpty == true ? "false" : "true",
            "endpoint": "/v1/stories/generate"
        ])

        // Hikaye üretimi LLM/medya adımları nedeniyle diğer endpoint'lere göre daha uzun sürebilir.
        let endpoint = APIEndpoint(
            path: "/v1/stories/generate",
            method: .post,
            timeoutInterval: 180
        )
        let body = StoryGenerateRequestDTO(
            childId: childId,
            theme: theme,
            language: language,
            extraContext: extraContext,
            selectedInterests: selectedInterests,
            storyGoal: storyGoal
        )

        let maxAttempts = 2
        for attempt in 1...maxAttempts {
            do {
                let data: StoryGenerateDataDTO = try await client.request(endpoint, body: body)
                AppLogger.info("stories.generate.response_received", [
                    "childId": childId.uuidString,
                    "theme": theme,
                    "storyId": data.story.id.uuidString,
                    "result": "ok",
                    "attempt": "\(attempt)"
                ])
                return data.story
            } catch let err as APIClientError {
                if attempt < maxAttempts, shouldRetryGenerate(err) {
                    AppLogger.info("stories.generate.retrying", [
                        "childId": childId.uuidString,
                        "theme": theme,
                        "attempt": "\(attempt)",
                        "nextAttempt": "\(attempt + 1)",
                        "errorKind": "\(err)"
                    ])
                    try await Task.sleep(nanoseconds: retryDelay(forAttempt: attempt))
                    continue
                }

                let code: String
                switch err {
                case .decodingFailed:
                    code = "decode_failed"
                case .unauthorized:
                    code = "unauthorized"
                case .server(let c, _):
                    code = c
                default:
                    code = "client_error"
                }
                AppLogger.error("stories.generate.failed", [
                    "childId": childId.uuidString,
                    "theme": theme,
                    "attempt": "\(attempt)",
                    "errorKind": "\(err)",
                    "errorCode": code
                ])
                if case .decodingFailed = err {
                    AppLogger.error("stories.generate.decode_failed", [
                        "childId": childId.uuidString,
                        "theme": theme
                    ])
                }
                throw err
            } catch {
                AppLogger.error("stories.generate.failed", [
                    "childId": childId.uuidString,
                    "theme": theme,
                    "attempt": "\(attempt)",
                    "errorKind": "unknown"
                ])
                throw error
            }
        }
        throw APIClientError.invalidResponse
    }

    static func fetchStories(limit: Int = 20) async throws -> [StoryModel] {
        let endpoint = APIEndpoint(
            path: "/v1/stories",
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        let data: StoryListDataDTO = try await client.request(endpoint)
        return data.stories
    }

    static func fetchStory(id: UUID) async throws -> StoryModel {
        let endpoint = APIEndpoint(path: "/v1/stories/\(id.uuidString)", method: .get)
        let data: StoryDetailDataDTO = try await client.request(endpoint)
        return data.story
    }

    static func deleteStory(id: UUID) async throws {
        let endpoint = APIEndpoint(path: "/v1/stories/\(id.uuidString)", method: .delete)
        let _: StoryDetailDataDTO = try await client.request(endpoint)
    }

    private static func shouldRetryGenerate(_ error: APIClientError) -> Bool {
        switch error {
        case .networkFailure:
            return true
        case .server(let code, _):
            let normalized = code.uppercased()
            return normalized == "INTERNAL_SERVER_ERROR"
                || normalized == "BAD_GATEWAY"
                || normalized == "SERVICE_UNAVAILABLE"
                || normalized == "GATEWAY_TIMEOUT"
        default:
            return false
        }
    }

    private static func retryDelay(forAttempt attempt: Int) -> UInt64 {
        let seconds = attempt == 1 ? 2 : 4
        return UInt64(seconds) * 1_000_000_000
    }
}
