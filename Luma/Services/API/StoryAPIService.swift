import Foundation

/// POST /v1/stories/generate — yalnızca hikâyeye özel alanlar; çocuk profili sunucuda okunur.
struct StoryGenerateRequestDTO: Encodable {
    /// Kayıtlı profil seçiliyse dolu; değilse `childName` ile geçici (kalıcı olmayan) üretim yapılır.
    let childId: UUID?
    let childName: String?
    let childAge: Int?
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
        childId: UUID?,
        childName: String? = nil,
        childAge: Int? = nil,
        theme: String,
        language: String? = nil,
        extraContext: String? = nil,
        selectedInterests: [String]? = nil,
        storyGoal: String? = nil
    ) async throws -> StoryModel {
        let childLogId = childId?.uuidString ?? "ad_hoc"
        // Kurtarma (hata sonrası liste taraması) yalnızca BU isteğin başlamasından sonra oluşan masalı kabul eder;
        // yoksa bir önceki masal (ekstra detaysız) bu isteğin sonucu gibi gösterilebilirdi.
        let requestStartedAt = Date()
        AppLogger.info("stories.generate.request_sent", [
            "childId": childLogId,
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
            childName: childId == nil ? childName : nil,
            childAge: childId == nil ? childAge : nil,
            theme: theme,
            language: language,
            extraContext: extraContext,
            selectedInterests: selectedInterests,
            storyGoal: storyGoal
        )

        let maxAttempts = 4
        var lastError: Error?
        _ = childLogId

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
                    "childId": childLogId,
                    "theme": theme,
                    "storyId": story.id.uuidString,
                    "result": "ok",
                    "attempt": "\(attempt)"
                ])
                return story
            } catch let err as APIClientError {
                lastError = err
                // Önceki deneme sunucuda tamamlanmış olabilir (ağ geçidi hatası yanıtı düşürür). Yeniden denemeden ya da
                // "hak doldu" (402) sonucunu göstermeden önce masal zaten oluştuysa onu kullan: aksi halde ücretsiz
                // kullanıcı kendi ürettiği masalın hakkı yüzünden paywall görür.
                if attempt > 1 || shouldRetryGenerate(err) || err.allowsStoryGenerateListRecovery {
                    if let recovered = await recoverRecentlyGeneratedStory(childId: childId, theme: theme, since: requestStartedAt) {
                        AppLogger.info("stories.generate.recovered_before_retry", [
                            "childId": childLogId,
                            "theme": theme,
                            "storyId": recovered.id.uuidString,
                            "attempt": "\(attempt)"
                        ])
                        return recovered
                    }
                }
                if attempt < maxAttempts, shouldRetryGenerate(err) {
                    AppLogger.info("stories.generate.retrying", [
                        "childId": childLogId,
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
                    "childId": childLogId,
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
                "childId": childLogId,
                "theme": theme,
                "errorKind": "\(apiErr)"
            ])
            try await Task.sleep(nanoseconds: 750_000_000)
            if let recovered = await recoverRecentlyGeneratedStory(childId: childId, theme: theme, since: requestStartedAt) {
                AppLogger.info("stories.generate.recovered_from_list", [
                    "childId": childLogId,
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
        childId: UUID?,
        theme: String,
        attempt: Int
    ) async throws -> StoryModel {
        let childLogId = childId?.uuidString ?? "ad_hoc"
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
                "childId": childLogId,
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

    private static func recoverRecentlyGeneratedStory(childId: UUID?, theme: String, since requestStartedAt: Date) async -> StoryModel? {
        let childLogId = childId?.uuidString ?? "ad_hoc"
        let themeNorm = theme.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Sunucu/cihaz saat farkına karşı küçük tolerans (10 sn).
        let cutoff = requestStartedAt.addingTimeInterval(-10)
        do {
            let stories = try await fetchStories(limit: 100)
            let candidates = stories.filter { story in
                guard story.child_id == childId else { return false } // nil == nil: profilsiz (ad-hoc) masallar
                guard let created = story.created_at, created >= cutoff else { return false }
                let t = story.theme.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return t == themeNorm
            }
            return candidates.max(by: { ($0.created_at ?? .distantPast) < ($1.created_at ?? .distantPast) })
        } catch {
            AppLogger.error("stories.generate.recovery_fetch_failed", [
                "childId": childLogId,
                "theme": theme,
                "error": String(describing: error)
            ])
            return nil
        }
    }

    private static func logGenerateFailure(_ err: APIClientError, childId: UUID?, theme: String, attempt: Int) {
        let childLogId = childId?.uuidString ?? "ad_hoc"
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
            "childId": childLogId,
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
        AppLogger.info("stories.narrate.request_sent", [
            "storyId": id.uuidString,
            "path": endpoint.path
        ])
        do {
            let data: StoryNarrateDataDTO = try await client.request(endpoint, body: nil)
            if let direct = data.audioUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !direct.isEmpty {
                AppLogger.info("stories.narrate.response_ok", [
                    "storyId": id.uuidString,
                    "field": "audioUrl"
                ].merging(AppLogger.narrationURLSummaryFields(direct)) { _, new in new })
                return direct
            }
            if let snake = data.audio_url?.trimmingCharacters(in: .whitespacesAndNewlines), !snake.isEmpty {
                AppLogger.info("stories.narrate.response_ok", [
                    "storyId": id.uuidString,
                    "field": "audio_url"
                ].merging(AppLogger.narrationURLSummaryFields(snake)) { _, new in new })
                return snake
            }
            let storyCamel = data.story?.audioUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
            let storySnake = data.story?.audio_url?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let s = storyCamel, !s.isEmpty {
                AppLogger.info("stories.narrate.response_ok", [
                    "storyId": id.uuidString,
                    "field": "story.audioUrl"
                ].merging(AppLogger.narrationURLSummaryFields(s)) { _, new in new })
                return s
            }
            if let s = storySnake, !s.isEmpty {
                AppLogger.info("stories.narrate.response_ok", [
                    "storyId": id.uuidString,
                    "field": "story.audio_url"
                ].merging(AppLogger.narrationURLSummaryFields(s)) { _, new in new })
                return s
            }
            AppLogger.error("stories.narrate.no_audio_url_in_payload", [
                "storyId": id.uuidString,
                "hasStoryNested": data.story != nil ? "true" : "false"
            ])
            throw APIClientError.decodingFailed
        } catch let error as APIClientError {
            logStoryNarrateAPIClientError(error, storyId: id)
            throw error
        } catch {
            AppLogger.error("stories.narrate.unexpected_error", [
                "storyId": id.uuidString,
                "errorType": String(describing: type(of: error))
            ])
            throw error
        }
    }

    private static func logStoryNarrateAPIClientError(_ error: APIClientError, storyId: UUID) {
        let sid = ["storyId": storyId.uuidString]
        switch error {
        case .paymentRequired(let apiCode, _):
            AppLogger.error("stories.narrate.api_payment_required", sid.merging([
                "apiCode": apiCode ?? ""
            ]) { _, new in new })
        case .unauthorized:
            AppLogger.error("stories.narrate.api_unauthorized", sid)
        case .invalidURL:
            AppLogger.error("stories.narrate.api_invalid_url", sid)
        case .decodingFailed:
            AppLogger.error("stories.narrate.api_decoding_failed", sid)
        case .invalidResponse:
            AppLogger.error("stories.narrate.api_invalid_response", sid)
        case .emptyData:
            AppLogger.error("stories.narrate.api_empty_data", sid)
        case .networkFailure(let message):
            AppLogger.error("stories.narrate.api_network", sid.merging([
                "messageSnippet": String(message.prefix(160))
            ]) { _, new in new })
        case .server(let code, let message):
            AppLogger.error("stories.narrate.api_server", sid.merging([
                "code": code,
                "messageSnippet": String(message.prefix(160))
            ]) { _, new in new })
        }
    }

    private static func shouldRetryGenerate(_ error: APIClientError) -> Bool {
        switch error {
        case .networkFailure:
            // Zaman aşımında sunucu masalı üretmeye/kaydetmeye devam edebilir; körlemesine yeniden denemek
            // ikinci bir masal ve ikinci bir ücret demektir. Bunun yerine liste ile kurtarma denenir.
            return false
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
