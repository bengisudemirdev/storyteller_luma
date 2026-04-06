//
//  StoryService.swift
//  Luma
//
//  Masal işlemleri (Express API). Tek kaynak.
//

import Foundation

enum StoryService {

    /// Giriş yapmış kullanıcının kayıtlı masallarını döner.
    static func fetchSavedStories() async throws -> [StoryModel] {
        return try await StoryAPIService.fetchStories(limit: 20)
    }

    /// Kalıcı çocuk tercihleri sunucuda `childId` ile okunur; burada yalnızca bu masala özel alanlar gider.
    static func generateStory(
        childId: UUID,
        theme: String,
        language: String? = nil,
        extraContext: String? = nil,
        selectedInterests: [String]? = nil,
        storyGoal: String? = nil
    ) async throws -> StoryModel {
        return try await StoryAPIService.generateStory(
            childId: childId,
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
}
