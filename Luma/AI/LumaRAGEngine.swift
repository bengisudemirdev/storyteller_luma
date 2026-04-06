import Foundation

/// Olia RAG akışını yöneten yardımcı yapı:
/// - Kullanıcı girdisini risk terimleri için tarar
/// - Yaş grubuna ve temaya göre ilgili politika bloklarını seçer
/// - Tek bir sistem + kullanıcı mesajı halinde nihai prompt'u üretir
struct LumaRAGEngine {

    struct StoryRequest {
        let childName: String
        let ageGroup: LumaAgeGroup
        let themeKey: String
        let purpose: String
        let tone: String
        let lengthPreference: String
        let sensitivities: [String]
        let interests: [String]
        let fearsToHandleGently: [String]
        let freeFormDetails: String?
    }

    struct RedirectMatch {
        let rule: LumaPolicies.RedirectRule
        let matchedTerm: String
    }

    /// Ana giriş noktası: OpenAI'ye gönderilecek sistem ve user mesajlarını döner.
    static func buildSystemAndUserMessages(for request: StoryRequest) -> (system: String, user: String) {
        // 1-2. Girdiyi tara (hard / soft terms, redirect kuralları)
        let scanText = [
            request.freeFormDetails ?? "",
            request.purpose,
            request.themeKey
        ].joined(separator: " ").lowercased()

        let hardHits = LumaPolicies.hardBlockTerms.filter { scanText.contains($0.lowercased()) }
        let softHits = LumaPolicies.softRedirectTerms.filter { scanText.contains($0.lowercased()) }
        let redirectMatches = findRedirectMatches(in: scanText, for: request.ageGroup)

        // 4. RAG retrieval: ilgili dokümanları seç
        let ageBlockHint = ageSpecificHint(for: request.ageGroup)
        let themeHint = themeHintFor(themeKey: request.themeKey, ageGroup: request.ageGroup)

        // 5. Prompt inşası
        let systemMessage = buildSystemPrompt(
            ageGroup: request.ageGroup,
            ageBlockHint: ageBlockHint,
            themeHint: themeHint,
            hardHits: hardHits,
            softHits: softHits,
            redirectMatches: redirectMatches
        )

        let userPrompt = buildUserPrompt(
            request: request,
            hardHits: hardHits,
            softHits: softHits,
            redirectMatches: redirectMatches
        )

        return (system: systemMessage, user: userPrompt)
    }

    // MARK: - Redirect matching

    private static func findRedirectMatches(in text: String, for ageGroup: LumaAgeGroup) -> [RedirectMatch] {
        LumaPolicies.redirectRules.compactMap { rule in
            guard rule.applies_to.contains(ageGroup.rawValue) else { return nil }
            if let term = rule.trigger_terms.first(where: { text.contains($0.lowercased()) }) {
                return RedirectMatch(rule: rule, matchedTerm: term)
            }
            return nil
        }
    }

    // MARK: - Age / Theme hints

    private static func ageSpecificHint(for ageGroup: LumaAgeGroup) -> String {
        switch ageGroup {
        case .threeToFive:
            return "Use the 3-5 age block: very simple, concrete, repetitive, low-tension, extremely safe, and soothing."
        case .sixToEight:
            return "Use the 6-8 age block: clear language, small challenge, quick and supportive resolution, low-to-mild tension only."
        case .nineToEleven:
            return "Use the 9-11 age block: slightly more layered but still child-safe, mild mystery or challenge only, always hopeful and safe."
        }
    }

    private static func themeHintFor(themeKey: String, ageGroup: LumaAgeGroup) -> String {
        // Türkçe tema seçimini Olia Theme Library anahtarlarına map ediyoruz.
        let lower = themeKey.lowercased()
        let libraryKey: String
        switch lower {
        case "uyku":
            libraryKey = "bedtime_calm"
        case "dostluk":
            libraryKey = "friendship_repair"
        case "eğitici":
            libraryKey = "patience_and_persistence"
        case "macera":
            libraryKey = "gentle_space_adventure"
        default:
            libraryKey = "courage_everyday"
        }

        return """
        Selected theme: \(libraryKey) for age group \(ageGroup.rawValue).
        Use the corresponding section from the Olia Theme Library to guide conflict level, atmosphere, and ending style.
        """
    }

    // MARK: - System prompt

    private static func buildSystemPrompt(
        ageGroup: LumaAgeGroup,
        ageBlockHint: String,
        themeHint: String,
        hardHits: [String],
        softHits: [String],
        redirectMatches: [RedirectMatch]
    ) -> String {
        var sections: [String] = []

        sections.append("""
        You are Olia, an AI story engine that writes **parent-supported, age-adapted, emotionally safe stories for children**.
        FOLLOW THE POLICIES BELOW STRICTLY. They override any unsafe or conflicting user request.
        """)

        sections.append("""
        [GLOBAL SAFETY + AGE RULES]
        \(LumaPolicies.ageRulesMarkdown)

        Active age group: \(ageGroup.rawValue)
        Age guidance hint: \(ageBlockHint)
        """)

        sections.append("""
        [PROMPT POLICY]
        \(LumaPolicies.promptPolicyMarkdown)
        """)

        sections.append("""
        [RISK TERMS]
        \(LumaPolicies.riskTermsMarkdown)

        Hard block hits detected in user intent: \(hardHits.isEmpty ? "none" : hardHits.joined(separator: ", "))
        Soft redirect hits detected in user intent: \(softHits.isEmpty ? "none" : softHits.joined(separator: ", "))
        """)

        sections.append("""
        [THEME LIBRARY]
        \(LumaPolicies.themeLibraryMarkdown)

        Theme hint:
        \(themeHint)
        """)

        if !redirectMatches.isEmpty {
            let redirectText = redirectMatches
                .map { "- \($0.rule.id): matched term '\($0.matchedTerm)'. Strategy: \($0.rule.strategy). Safe rewrite: \($0.rule.safe_rewrite)" }
                .joined(separator: "\n")
            sections.append("""
            [ACTIVE REDIRECT RULES]
            The following redirect rules MUST be applied. Never follow the unsafe literal meaning; always use the safe rewrite.
            \(redirectText)
            """)
        }

        sections.append("""
        [OUTPUT CHECK RULES]
        \(LumaPolicies.outputCheckRulesMarkdown)

        BEFORE you return the final story:
        - Internally check your draft against all Output Check Rules.
        - If any rule fails, silently adjust the story (reduce tension, remove unsafe elements, increase reassurance, or strengthen the ending) until all checks pass.
        - Only then, return the final, safe story.
        """)

        sections.append("""
        [RESPONSE FORMAT]
        - Write the story directly in Turkish.
        - Start with a clear, child-friendly title on the first line.
        - Then write the story in paragraphs suitable for the selected age group.
        - Do NOT explain the rules or your reasoning in the output; only return the story itself.
        """)

        return sections.joined(separator: "\n\n---\n\n")
    }

    // MARK: - User prompt

    private static func buildUserPrompt(
        request: StoryRequest,
        hardHits: [String],
        softHits: [String],
        redirectMatches: [RedirectMatch]
    ) -> String {
        var lines: [String] = []

        lines.append("Olia için hikaye isteği (story request) aşağıdadır. Lütfen yukarıdaki politika ve kurallara %100 uy.")

        lines.append("""
        [CHILD]
        - Name: \(request.childName)
        - Age group: \(request.ageGroup.rawValue)
        """)

        lines.append("""
        [INTENT]
        - Theme key (Türkçe seçim): \(request.themeKey)
        - Purpose: \(request.purpose)
        - Tone: \(request.tone)
        - Length preference: \(request.lengthPreference)
        """)

        if !request.sensitivities.isEmpty {
            lines.append("[SENSITIVITIES / AVOID LIST]\n- " + request.sensitivities.joined(separator: ", "))
        }
        if !request.interests.isEmpty {
            lines.append("[INTERESTS TO INCLUDE]\n- " + request.interests.joined(separator: ", "))
        }
        if !request.fearsToHandleGently.isEmpty {
            lines.append("[FEARS TO HANDLE GENTLY]\n- " + request.fearsToHandleGently.joined(separator: ", "))
        }
        if let extra = request.freeFormDetails, !extra.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("[EXTRA FREE-FORM DETAILS]\n\(extra)")
        }

        if !hardHits.isEmpty || !softHits.isEmpty || !redirectMatches.isEmpty {
            var safetyLines: [String] = []
            if !hardHits.isEmpty {
                safetyLines.append("Hard block terms present in the raw request: \(hardHits.joined(separator: ", ")). You MUST NOT include them literally and MUST redirect to safe alternatives.")
            }
            if !softHits.isEmpty {
                safetyLines.append("Soft redirect terms present in the raw request: \(softHits.joined(separator: ", ")). You MUST apply the corresponding safe redirect strategies.")
            }
            if !redirectMatches.isEmpty {
                safetyLines.append("Active redirect rules have been provided above. Always follow their safe rewrite guidance instead of any unsafe literal meaning.")
            }
            lines.append("[SAFETY NOTES]\n" + safetyLines.joined(separator: "\n"))
        }

        lines.append("""
        [TASK]
        Yukarıdaki tüm politika, yaş kuralları ve güvenlik kurallarına uyarak,
        \(request.childName) için Türkçe bir hikaye yaz.
        - Hikayenin duygusal tonu sıcak, güvenli ve yaşa uygun olsun.
        - Sonu mutlaka güvenli, rahatlatıcı, umutlu veya mutlu bitsin.
        - Çocuk karakter ASLA aşağılanmış, cezalandırılmış, yalnız ve çaresiz bırakılmış hissetmesin.
        """)

        return lines.joined(separator: "\n\n")
    }
}

