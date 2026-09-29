import Foundation

/// Küçük Türkçe dilbilgisi yardımcıları (ünlü uyumu).
enum TurkishGrammar {
    private static let tr = Locale(identifier: "tr")

    private static func isVowel(_ c: Character) -> Bool {
        "aeıioöuü".contains(String(c).lowercased(with: tr))
    }

    /// İlgi (tamlayan) eki: "Defne" → "Defne'nin", "Deniz" → "Deniz'in", "Kaan" → "Kaan'ın", "Ali" → "Ali'nin".
    static func genitive(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last else { return trimmed }
        guard let lastVowel = trimmed.last(where: isVowel) else { return trimmed + "'ın" }

        let suffixVowel: String
        switch String(lastVowel).lowercased(with: tr) {
        case "a", "ı": suffixVowel = "ı"
        case "e", "i": suffixVowel = "i"
        case "o", "u": suffixVowel = "u"
        default: suffixVowel = "ü" // ö, ü
        }
        return trimmed + "'" + (isVowel(last) ? "n" : "") + suffixVowel + "n"
    }

    /// Masal için yedek başlık: "Defne'nin Masalı".
    static func fallbackStoryTitle(for childName: String) -> String {
        let name = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Masal" : "\(genitive(name)) Masalı"
    }
}
