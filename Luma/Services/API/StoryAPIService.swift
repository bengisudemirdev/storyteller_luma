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

/// `POST /v1/stories/{id}/narrate` → `success.data` (belgelendirilmiş şema).
private struct StoryNarrateDataDTO: Decodable {
    let audioUrl: String?
    let audio_url: String?
    let audioProvider: String?
    let audioModel: String?
    let audioVoiceId: String?
    let charactersUsed: Int?
    let paymentSource: String?
    let voiceRemainingThisMonth: Int?
    let extraVoiceCredits: Int?
    /// Eski/alternatif yanıtlarda gömülü masal.
    let story: StoryModel?

    enum CodingKeys: String, CodingKey {
        case audioUrl
        case audio_url
        case audioProvider
        case audioModel
        case audioVoiceId
        case charactersUsed
        case paymentSource
        case voiceRemainingThisMonth
        case extraVoiceCredits
        case story
    }
}

// MARK: - Esnek üretim yanıtı (`success`/`data` olmadan veya gömülü `story`)

private struct LooseAPIEnvelope<T: Decodable>: Decodable {
    let success: Bool?
    let data: T?
    let error: APIErrorPayload?
}

private struct FlexibleStoryPayload: Decodable {
    let value: StoryModel

    init(from decoder: Decoder) throws {
        self.value = try StoryModel.decodeFlexibleGeneratePayload(from: decoder)
    }
}

private struct StoryNestedFlexibleDTO: Decodable {
    let story: FlexibleStoryPayload
}

enum StoryAPIService {
    private static let client = APIClient.shared

    private static let generatePayloadDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

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

        let endpoint = APIEndpoint(
            path: "/v1/stories/generate",
            method: .post,
            timeoutInterval: 90
        )
        let body = StoryGenerateRequestDTO(
            childId: childId,
            theme: theme,
            language: language,
            extraContext: extraContext,
            selectedInterests: selectedInterests,
            storyGoal: storyGoal
        )

        let maxAttempts = 4
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                let story = try await generateStoryOnce(
                    endpoint: endpoint,
                    body: body,
                    childId: childId,
                    theme: theme,
                    attempt: attempt
                )
                AppLogger.info("stories.generate.response_received", [
                    "childId": childId.uuidString,
                    "theme": theme,
                    "storyId": story.id.uuidString,
                    "result": "ok",
                    "attempt": "\(attempt)"
                ])
                return story
            } catch let err as APIClientError {
                lastError = err
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
                logGenerateFailure(err, childId: childId, theme: theme, attempt: attempt)
                break
            } catch {
                lastError = error
                AppLogger.error("stories.generate.failed", [
                    "childId": childId.uuidString,
                    "theme": theme,
                    "attempt": "\(attempt)",
                    "errorKind": "unknown"
                ])
                break
            }
        }

        guard let err = lastError else {
            throw APIClientError.invalidResponse
        }

        if let apiErr = err as? APIClientError, apiErr.allowsStoryGenerateListRecovery {
            AppLogger.info("stories.generate.recovery_attempt", [
                "childId": childId.uuidString,
                "theme": theme,
                "errorKind": "\(apiErr)"
            ])
            try await Task.sleep(nanoseconds: 750_000_000)
            if let recovered = await recoverRecentlyGeneratedStory(childId: childId, theme: theme, windowSeconds: 120) {
                AppLogger.info("stories.generate.recovered_from_list", [
                    "childId": childId.uuidString,
                    "theme": theme,
                    "storyId": recovered.id.uuidString
                ])
                return recovered
            }
        }

        throw err
    }

    private static func generateStoryOnce(
        endpoint: APIEndpoint,
        body: StoryGenerateRequestDTO,
        childId: UUID,
        theme: String,
        attempt: Int
    ) async throws -> StoryModel {
        let (data, http) = try await client.requestRawSuccessData(
            endpoint,
            body: body,
            urlSession: APIClient.storyGenerateURLSession
        )
        do {
            return try decodeStoryGeneratePayload(data: data, http: http)
        } catch {
            let preview = String(data: data.prefix(1000), encoding: .utf8) ?? "<binary>"
            AppLogger.error("stories.generate.payload_decode_failed", [
                "childId": childId.uuidString,
                "theme": theme,
                "attempt": "\(attempt)",
                "statusCode": "\(http.statusCode)",
                "responseBodyPreview": preview,
                "decodingError": String(describing: error)
            ])
            throw APIClientError.decodingFailed
        }
    }

    /// `/v1/stories/generate` gövdesi: API zarfı + `{ story }` veya doğrudan masal nesnesi.
    private static func decodeStoryGeneratePayload(data: Data, http: HTTPURLResponse) throws -> StoryModel {
        let decoder = generatePayloadDecoder

        if let env = try? decoder.decode(LooseAPIEnvelope<StoryGenerateDataDTO>.self, from: data),
           env.success != false,
           env.error == nil,
           let dto = env.data {
            return dto.story
        }

        if let env = try? decoder.decode(LooseAPIEnvelope<StoryNestedFlexibleDTO>.self, from: data),
           env.success != false,
           env.error == nil,
           let dto = env.data {
            return dto.story.value
        }

        if let env = try? decoder.decode(LooseAPIEnvelope<FlexibleStoryPayload>.self, from: data),
           env.success != false,
           env.error == nil,
           let dto = env.data {
            return dto.value
        }

        if let nested = try? decoder.decode(StoryNestedFlexibleDTO.self, from: data) {
            return nested.story.value
        }

        if let direct = try? decoder.decode(FlexibleStoryPayload.self, from: data) {
            return direct.value
        }

        let preview = String(data: data.prefix(1000), encoding: .utf8) ?? "<binary>"
        AppLogger.error("stories.generate.payload_decode_failed", [
            "statusCode": "\(http.statusCode)",
            "responseBodyPreview": preview,
            "decodingError": "all generate payload strategies failed"
        ])
        throw APIClientError.decodingFailed
    }

    private static func recoverRecentlyGeneratedStory(childId: UUID, theme: String, windowSeconds: TimeInterval) async -> StoryModel? {
        let themeNorm = theme.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cutoff = Date().addingTimeInterval(-windowSeconds)
        do {
            let stories = try await fetchStories(limit: 100)
            let candidates = stories.filter { story in
                guard story.child_id == childId else { return false }
                guard let created = story.created_at, created >= cutoff else { return false }
                let t = story.theme.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return t == themeNorm
            }
            return candidates.max(by: { ($0.created_at ?? .distantPast) < ($1.created_at ?? .distantPast) })
        } catch {
            AppLogger.error("stories.generate.recovery_fetch_failed", [
                "childId": childId.uuidString,
                "theme": theme,
                "error": String(describing: error)
            ])
            return nil
        }
    }

    private static func logGenerateFailure(_ err: APIClientError, childId: UUID, theme: String, attempt: Int) {
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

    /// İstemci gövdesi gönderilmez; path’teki `storyId` yeterli (`POST /v1/stories/{id}/narrate`).
    static func generateStoryAudioURL(id: UUID) async throws -> String {
        let endpoint = APIEndpoint(
            path: "/v1/stories/\(id.uuidString)/narrate",
            method: .post,
            timeoutInterval: 120
        )
        let data: StoryNarrateDataDTO = try await client.request(endpoint, body: nil)
        if let direct = data.audioUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !direct.isEmpty {
            return direct
        }
        if let snake = data.audio_url?.trimmingCharacters(in: .whitespacesAndNewlines), !snake.isEmpty {
            return snake
        }
        let storyCamel = data.story?.audioUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        let storySnake = data.story?.audio_url?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = storyCamel, !s.isEmpty { return s }
        if let s = storySnake, !s.isEmpty { return s }
        throw APIClientError.decodingFailed
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
                || normalized == "REQUEST_TIMEOUT"
                || normalized == "OPENAI_REQUEST_FAILED"
                || normalized == "OPENAI_UPSTREAM_ERROR"
                || normalized == "OPENAI_TIMEOUT"
                || normalized == "OPENAI_RATE_LIMITED"
        default:
            return false
        }
    }

    private static func retryDelay(forAttempt attempt: Int) -> UInt64 {
        let seconds: UInt64
        switch attempt {
        case 1: seconds = 2
        case 2: seconds = 5
        default: seconds = 10
        }
        return seconds * 1_000_000_000
    }
}
