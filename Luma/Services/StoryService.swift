//
//  StoryService.swift
//  Luma
//
//  Masal işlemleri (Express API). Tek kaynak.
//

import Foundation

enum StoryService {
    static func fetchClassicTales() async throws -> [ClassicTaleItem] {
        try await ClassicTalesAPIService.fetchClassicTales()
    }

    static func fetchClassicTaleDetail(taleId: String) async throws -> ClassicTaleItem? {
        try await ClassicTalesAPIService.fetchClassicTaleDetail(taleId: taleId)
    }

    /// Giriş yapmış kullanıcının kayıtlı masallarını döner (`limit` üst sınırı API ile uyumlu).
    static func fetchSavedStories(limit: Int = 20) async throws -> [StoryModel] {
        try await StoryAPIService.fetchStories(limit: limit)
    }

    /// Kalıcı çocuk tercihleri sunucuda `childId` ile okunur; burada yalnızca bu masala özel alanlar gider.
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
        return try await StoryAPIService.generateStory(
            childId: childId,
            childName: childName,
            childAge: childAge,
            theme: theme,
            language: language,
            extraContext: extraContext,
            selectedInterests: selectedInterests,
            storyGoal: storyGoal
        )
    }

    /// Belirli bir masalı (id ile) siler.
    static func deleteStory(id: UUID) async throws {
        try await StoryAPIService.deleteStory(id: id)
    }

    /// Belirli bir masal için backend üzerinden seslendirme üretir ve audio URL döner.
    static func generateStoryAudioURL(id: UUID) async throws -> String {
        try await StoryAPIService.generateStoryAudioURL(id: id)
    }

    /// Sunucu ile uyumlu uç: `POST /v1/stories/{id}/audio` (`StoryAPIService.generateStoryAudioURL`).
    static func narrateStory(id: UUID) async throws -> NarrationResponse {
        let urlString = try await StoryAPIService.generateStoryAudioURL(id: id)
        return NarrationResponse(
            audioUrl: urlString,
            audioProvider: nil,
            audioModel: nil,
            audioVoiceId: nil,
            charactersUsed: nil
        )
    }
}
