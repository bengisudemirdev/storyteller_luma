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
