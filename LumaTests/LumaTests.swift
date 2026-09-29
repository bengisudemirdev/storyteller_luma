//
//  LumaTests.swift
//  LumaTests
//
//  Created by Bengisu Demir on 18.02.2026.
//

import Testing
import UIKit
@testable import Luma

struct TurkishGrammarTests {
    @Test func genitiveFollowsVowelHarmony() {
        #expect(TurkishGrammar.genitive("Defne") == "Defne'nin")
        #expect(TurkishGrammar.genitive("Deniz") == "Deniz'in")
        #expect(TurkishGrammar.genitive("Kaan") == "Kaan'ın")
        #expect(TurkishGrammar.genitive("Ali") == "Ali'nin")
        #expect(TurkishGrammar.genitive("Ömer") == "Ömer'in")
        #expect(TurkishGrammar.genitive("Uğur") == "Uğur'un")
        #expect(TurkishGrammar.genitive("Elif") == "Elif'in")
        #expect(TurkishGrammar.genitive("Yusuf") == "Yusuf'un")
        #expect(TurkishGrammar.genitive("Sude") == "Sude'nin")
        #expect(TurkishGrammar.genitive("Işık") == "Işık'ın")
    }

    @Test func fallbackTitleUsesGenitive() {
        #expect(TurkishGrammar.fallbackStoryTitle(for: " Defne ") == "Defne'nin Masalı")
        #expect(TurkishGrammar.fallbackStoryTitle(for: "") == "Masal")
    }
}

struct StoryPaginationTests {
    private let sample = """
    Bir varmış bir yokmuş. Küçük bir kasabada Defne adında bir kız yaşarmış. Her sabah bahçesindeki çiçekleri sularmış.

    Bir gün bahçenin ucunda parlayan bir anahtar bulmuş. Anahtar sanki ona bir şey anlatmak istermiş. Defne merakla anahtarın peşine düşmüş.

    Yolda konuşan bir sincapla karşılaşmış. Sincap ona gizli bir kapıdan söz etmiş. İkisi birlikte ormana doğru yürümüş.
    """

    @Test func paragraphsSplitOnBlankLines() {
        #expect(StoryReadingPagination.paragraphs(from: sample).count == 3)
    }

    @Test func singleHugeBlockIsGroupedIntoParagraphs() {
        let block = Array(repeating: "Bu bir deneme cümlesidir ve okunabilir olmalıdır.", count: 30).joined(separator: " ")
        let paras = StoryReadingPagination.paragraphs(from: block)
        #expect(paras.count > 1)
        #expect(paras.allSatisfy { $0.count <= 520 })
    }

    @Test func pagesNeverSplitMidSentenceAndKeepAllText() {
        let width: CGFloat = 300
        let pages = StoryReadingPagination.pages(from: sample, textWidth: width, firstPageHeight: 220, otherPageHeight: 300)
        #expect(pages.count > 1)

        let original = sample.replacingOccurrences(of: "\n\n", with: " ").split(separator: " ").joined(separator: " ")
        let rebuilt = pages.flatMap { $0 }.joined(separator: " ").split(separator: " ").joined(separator: " ")
        #expect(rebuilt == original, "Sayfalama metin kaybetmemeli/eklememeli")

        for page in pages {
            for fragment in page {
                #expect(fragment.last.map { ".!?\"”'".contains($0) } ?? false, "Parça cümle sonunda bitmeli: \(fragment)")
            }
        }
    }

    @Test func pagesRespectMeasuredHeight() {
        let width: CGFloat = 300
        let limit: CGFloat = 260
        let pages = StoryReadingPagination.pages(from: sample, textWidth: width, firstPageHeight: limit, otherPageHeight: limit)
        for page in pages {
            let height = page.reduce(CGFloat(0)) { $0 + StoryTextMetrics.bodyHeight($1, width: width) }
                + CGFloat(max(page.count - 1, 0)) * StoryReadingPagination.paragraphSpacing
            #expect(height <= limit, "Sayfa yüksekliği sınırı aşmamalı (\(height) > \(limit))")
        }
    }
}

struct StoryModelDecodingTests {
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private let profilelessStory = """
    {"id":"11111111-1111-4111-8111-111111111111","user_id":"22222222-2222-4222-8222-222222222222",
     "child_id":null,"title":"Defne'nin Masalı","content":"Bir varmış bir yokmuş.","theme":"uyku",
     "age_group":"6-8","language":"Türkçe","cover_image_url":null,"audio_url":null,"created_at":"2026-09-30T10:00:00Z"}
    """

    @Test func storyWithNullChildIdDecodes() throws {
        let story = try decoder().decode(StoryModel.self, from: Data(profilelessStory.utf8))
        #expect(story.child_id == nil)
        #expect(story.title == "Defne'nin Masalı")
    }

    @Test func oneProfilelessStoryDoesNotBreakTheWholeList() throws {
        let withChild = profilelessStory.replacingOccurrences(of: "\"child_id\":null", with: "\"child_id\":\"33333333-3333-4333-8333-333333333333\"")
            .replacingOccurrences(of: "11111111-1111-4111-8111-111111111111", with: "44444444-4444-4444-8444-444444444444")
        let json = "{\"stories\":[\(withChild),\(profilelessStory)]}"
        let list = try decoder().decode(StoryListDataDTO.self, from: Data(json.utf8))
        #expect(list.stories.count == 2)
        #expect(list.stories[0].child_id != nil)
        #expect(list.stories[1].child_id == nil)
    }
}

struct GeneratePayloadDecodingTests {
    private struct Wrapper: Decodable {
        let story: StoryModel
        init(from decoder: Decoder) throws {
            story = try StoryModel.decodeFlexibleGeneratePayload(from: decoder)
        }
    }

    /// Backend `POST /v1/stories/generate` yanıtı: profil seçilmediğinde `childId: null`.
    @Test func generateResponseWithoutChildDecodes() throws {
        let json = """
        {"id":"11111111-1111-4111-8111-111111111111","storyId":"11111111-1111-4111-8111-111111111111",
         "title":"Defne ve Gökkuşağı","content":"Bir varmış bir yokmuş.","theme":"uyku","childId":null,
         "createdAt":"2026-09-30T10:00:00.000Z","ageGroup":"6-8","language":"Türkçe","coverImageUrl":null,"audioUrl":null}
        """
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let decoded = try d.decode(Wrapper.self, from: Data(json.utf8))
        #expect(decoded.story.child_id == nil)
        #expect(decoded.story.title == "Defne ve Gökkuşağı")
    }
}
