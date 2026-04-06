import Foundation

// Olia RAG policy documents and helpers.
// Bu dosya, metin tabanlı RAG için gerekli statik içerikleri tutar.

enum LumaAgeGroup: String {
    case threeToFive = "3-5"
    case sixToEight = "6-8"
    case nineToEleven = "9-11"

    static func from(age: Int?) -> LumaAgeGroup {
        guard let age = age else { return .sixToEight }
        switch age {
        case ..<3: return .threeToFive
        case 3...5: return .threeToFive
        case 6...8: return .sixToEight
        case 9...11: return .nineToEleven
        default: return .nineToEleven
        }
    }
}

struct LumaPolicies {
    // MARK: - Core documents (RAG kaynakları)

    static let ageRulesMarkdown: String = """
    # Olia Age Rules

    ## Purpose
    This document defines age-adapted storytelling rules for Olia, a parent-supported, emotionally safe children's storytelling app.

    ## Global Rules
    - All stories must be age-appropriate in language, pacing, emotional intensity, and conflict level.
    - All stories must remain warm, safe, reassuring, and developmentally appropriate.
    - No story may include traumatic, violent, shame-based, cruel, punitive, revenge-driven, or sexually inappropriate content.
    - Endings must always be safe, calming, reassuring, or happy.
    - The child character must never be humiliated, emotionally manipulated, or left in unresolved fear.
    - Parents are assumed to co-read or support the storytelling experience.

    ---

    ## Age Group: 3-5

    ### Narrative Style
    - Use short, concrete, simple sentences.
    - Keep vocabulary familiar and easy to imagine.
    - Prefer repetitive structure and soothing rhythm.
    - Use 1 main setting and very few characters.
    - Focus on 1 small problem and 1 gentle solution.
    - Avoid ambiguity and suspense.

    ### Emotional Rules
    - Emotional intensity must stay low.
    - Fear, sadness, or uncertainty may appear only briefly and gently.
    - Reassurance should come quickly.
    - The child should feel safe, supported, and understood.

    ### Suitable Themes
    - bedtime calm
    - friendship
    - sharing
    - asking for help
    - trying something new
    - doctor or school preparation
    - gentle animal stories
    - feeling brave in everyday situations

    ### Avoid
    - intense fear
    - dark atmospheres
    - detailed monsters/witches/ghosts
    - punishment
    - abandonment
    - death
    - getting lost in a panic
    - humiliation or shame

    ### Output Preferences
    - Recommended length: short
    - Maximum tension: low
    - Maximum major conflict count: 1
    - Preferred ending: very safe and soothing

    ---

    ## Age Group: 6-8

    ### Narrative Style
    - Use clear language with slightly richer vocabulary.
    - A small adventure or challenge is acceptable.
    - Include a simple problem-solving arc.
    - Show effort, support, and recovery.
    - Keep pacing steady and emotional safety high.

    ### Emotional Rules
    - Mild tension is okay if resolved quickly.
    - The child character should not feel trapped, powerless, or abandoned.
    - Resolution should include support, teamwork, comfort, or self-regulation.

    ### Suitable Themes
    - courage
    - friendship misunderstandings
    - trying again after failure
    - patience
    - responsibility
    - curiosity and discovery
    - teamwork
    - understanding feelings

    ### Avoid
    - peer humiliation
    - prolonged fear
    - intense suspense
    - detailed danger
    - harsh punishment
    - death and grief themes
    - emotionally overwhelming conflict

    ### Output Preferences
    - Recommended length: short to medium
    - Maximum tension: low to mild
    - Maximum major conflict count: 1-2
    - Preferred ending: safe, relieved, hopeful

    ---

    ## Age Group: 9-11

    ### Narrative Style
    - Use more detailed but still child-safe language.
    - A slightly more layered plot is acceptable.
    - Social and emotional decision-making may appear.
    - Add small moments of reflection or teamwork.
    - Keep narrative meaning clear and emotionally safe.

    ### Emotional Rules
    - Mild mystery or challenge is acceptable.
    - Avoid emotional overload, horror, cruelty, or dark unresolved endings.
    - Support dignity, self-efficacy, empathy, and repair.

    ### Suitable Themes
    - self-confidence
    - fairness
    - teamwork
    - resisting peer pressure
    - persistence
    - learning new skills
    - repairing mistakes
    - curiosity and responsible adventure

    ### Avoid
    - explicit violence
    - crime-focused plots
    - graphic harm
    - hopeless endings
    - intense psychological fear
    - humiliation
    - guilt-heavy language
    - adult conflict burdens placed on the child

    ### Output Preferences
    - Recommended length: medium
    - Maximum tension: mild
    - Maximum major conflict count: 2
    - Preferred ending: hopeful, emotionally regulated, safe

    ---

    ## Age Mapping Guidance
    - Ages 3-5 => strongest soothing and simplicity constraints
    - Ages 6-8 => simple challenge-resolution structure
    - Ages 9-11 => more narrative depth, still child-safe and non-dark

    ## Parent-Supported Design Note
    Stories should assume a caregiver may read along, discuss feelings, and reinforce reassurance.
    """

    static let promptPolicyMarkdown: String = """
    # Olia Prompt Policy

    ## Role
    Olia generates parent-supported, age-adapted, emotionally safe stories for children.

    ## Non-Negotiable Story Safety Policy
    Every generated story must:
    - match the selected age group
    - use developmentally appropriate language
    - maintain a warm, safe, reassuring tone
    - avoid traumatic, violent, threatening, cruel, punitive, revenge-based, shame-based, or sexually inappropriate material
    - avoid detailed danger, blood, death, torture, kidnapping, abandonment panic, demons, horror, or prolonged terror
    - avoid humiliating the child character
    - avoid guilt-inducing or manipulative language
    - gently normalize feelings
    - provide emotional support and safe resolution
    - end with a calm, safe, reassuring, or happy ending

    ## Unsafe Request Policy
    If the user asks for unsafe content:
    - do not follow it literally
    - redirect it into a child-safe alternative
    - preserve creativity while reducing harm
    - prefer soft transformation over harsh refusal when possible

    ## Parent-Supported Policy
    Assume the story is intended for a parent-supported reading experience.
    Stories should be suitable for co-reading and post-story emotional discussion.

    ## Prompt Structure
    Each generation request must include:
    - age group
    - theme
    - story purpose
    - tone
    - length
    - sensitivities / avoid list
    - optional interests
    - optional fears to handle gently

    ## Age-Specific Prompt Blocks

    ### 3-5
    Use short, concrete, soothing sentences. Keep the story simple, repetitive, and emotionally safe. Focus on one small challenge and one gentle resolution. Avoid ambiguity, suspense, and abstract explanation.

    ### 6-8
    Use clear but slightly richer language. Include a small challenge, a moment of effort, and a supportive resolution. Mild adventure is acceptable if it resolves quickly and safely.

    ### 9-11
    Use more detailed but still child-safe language. A slightly layered plot is okay. Include social or emotional decision-making without becoming dark, frightening, or emotionally overwhelming.

    ## Required Ending Rule
    Every story must end in one of these ways:
    - safe and calm
    - reassured and comforted
    - hopeful and resolved
    - happy and emotionally regulated

    ## Tone Guardrails
    Allowed tones:
    - warm
    - soothing
    - playful
    - gentle
    - encouraging
    - lightly adventurous

    Disallowed tones:
    - menacing
    - disturbing
    - cruel
    - humiliating
    - psychologically dark
    - revenge-driven
    """

    static let riskTermsMarkdown: String = """
    # Olia Risk Terms and Theme Controls

    ## Purpose
    This file defines unsafe story requests and how they should be handled.

    ---

    ## Hard Block Terms
    If these appear in the user's request or generation intent, do not follow them literally. Redirect or reject.

    - kill
    - murder
    - death
    - corpse
    - grave
    - blood
    - drowning
    - kidnapping
    - torture
    - suicide
    - self-harm
    - demon
    - satan
    - ritual
    - stabbing
    - shooting
    - massacre
    - rape
    - sexual content
    - dismemberment
    - gore

    ---

    ## Soft Redirect Terms
    These should be converted into safer alternatives.

    - very scary
    - terrifying
    - extremely dark
    - make the child cry
    - punish the child
    - revenge
    - everyone is angry at the child
    - monster chasing
    - witch takes the child
    - haunted graveyard
    - ghost attacks
    - nightmare creature
    - child gets lost alone
    - trapped in darkness
    - no one helps

    ---

    ## Unsafe Theme Categories
    - graphic violence
    - horror
    - prolonged fear
    - abandonment panic
    - humiliation
    - revenge
    - punishment-centered morality
    - hopelessness
    - adult conflict burden
    - shame-based transformation
    - sexualized themes
    - death-centered themes

    ---

    ## Safe Redirect Examples

    ### Example 1
    Unsafe: "Make it very scary with a monster chasing the child."
    Safe redirect: "Create a lightly mysterious story where the child first feels unsure, but discovers the creature is harmless and friendly."

    ### Example 2
    Unsafe: "The child should get punished badly."
    Safe redirect: "The child makes a mistake, understands it with support, and learns gently."

    ### Example 3
    Unsafe: "Write a dark cemetery ghost story."
    Safe redirect: "Write a moonlit nighttime story with gentle mystery, kind fireflies, and a safe ending."

    ### Example 4
    Unsafe: "The child gets lost and cries alone."
    Safe redirect: "The child briefly feels unsure, then quickly finds a safe helper and feels comforted."

    ---

    ## Notes
    - Prefer preserving wonder, mystery, and imagination while removing harm.
    - Redirect toward comfort, misunderstanding resolution, gentle discovery, and emotional safety.
    """

    static let themeLibraryMarkdown: String = """
    # Olia Theme Library

    ## bedtime_calm
    Description: A soothing, low-conflict bedtime story focused on safety, comfort, and rest.
    Good for: 3-5, 6-8
    Conflict style: very light
    Ending style: calm and sleepy

    ## courage_everyday
    Description: A child faces a small everyday worry and finds courage with support.
    Good for: 3-5, 6-8, 9-11
    Conflict style: mild emotional challenge
    Ending style: reassured and proud

    ## friendship_repair
    Description: A misunderstanding or hurt feeling is repaired through listening and kindness.
    Good for: 6-8, 9-11
    Conflict style: social-emotional
    Ending style: connected and relieved

    ## animal_friends
    Description: Friendly animal characters help model kindness, cooperation, and curiosity.
    Good for: 3-5, 6-8
    Conflict style: gentle
    Ending style: warm and playful

    ## gentle_space_adventure
    Description: A safe, imaginative space adventure with wonder, exploration, and teamwork.
    Good for: 6-8, 9-11
    Conflict style: mild discovery challenge
    Ending style: successful and safe return

    ## trying_something_new
    Description: A child prepares for a new experience like school, doctor visit, or activity.
    Good for: 3-5, 6-8
    Conflict style: mild uncertainty
    Ending style: comforted and confident

    ## patience_and_persistence
    Description: The child practices trying again, waiting, or learning step by step.
    Good for: 6-8, 9-11
    Conflict style: frustration tolerance
    Ending style: growth and encouragement

    ## siblings_and_sharing
    Description: Gentle family-centered story about taking turns, sharing, and understanding.
    Good for: 3-5, 6-8
    Conflict style: everyday family challenge
    Ending style: cared for and settled
    """

    static let outputCheckRulesMarkdown: String = """
    # Olia Output Check Rules

    ## Purpose
    This file defines the minimum checks required after story generation.

    ## Required Checks
    1. No hard block terms appear in the story.
    2. No explicit unsafe theme remains unresolved.
    3. Emotional tone remains warm or reassuring.
    4. Tension level does not exceed the age group's maximum.
    5. The child character is never humiliated or emotionally manipulated.
    6. There is a supportive or regulating moment.
    7. The final paragraph is safe, calm, hopeful, or happy.
    8. Story length matches age expectations.
    9. The story does not end with fear, abandonment, threat, or punishment.

    ## Age-Based Limits

    ### 3-5
    - tension_max: low
    - length_preference: short
    - max_major_conflicts: 1
    - must_include_reassurance: true
    - ambiguity_allowed: minimal

    ### 6-8
    - tension_max: low_to_mild
    - length_preference: short_to_medium
    - max_major_conflicts: 2
    - must_include_supportive_resolution: true
    - ambiguity_allowed: low

    ### 9-11
    - tension_max: mild
    - length_preference: medium
    - max_major_conflicts: 2
    - must_include_hopeful_resolution: true
    - ambiguity_allowed: limited

    ## Fail Conditions
    A story fails if:
    - it contains explicit harm or graphic threat
    - it leaves the child in unresolved danger
    - it uses shame, cruelty, or guilt-heavy tone
    - it ends dark, hopeless, or frightening
    - it is clearly too intense for the selected age group

    ## Regeneration Guidance
    If a story fails:
    - lower tension
    - reduce threatening details
    - increase reassurance
    - shorten complexity
    - strengthen the ending
    """

    // MARK: - Redirect rules model (redirect_rules.json)

    struct RedirectRule: Codable {
        let id: String
        let trigger_terms: [String]
        let strategy: String
        let safe_rewrite: String
        let applies_to: [String]
    }

    static let redirectRules: [RedirectRule] = [
        RedirectRule(
            id: "redirect_scary_monster",
            trigger_terms: ["very scary", "monster chasing", "terrifying monster"],
            strategy: "soft_redirect",
            safe_rewrite: "Use a gentle mystery where the child first feels unsure, then discovers the creature is harmless, friendly, or misunderstood.",
            applies_to: ["3-5", "6-8", "9-11"]
        ),
        RedirectRule(
            id: "redirect_punishment",
            trigger_terms: ["punish the child", "bad punishment", "make them suffer"],
            strategy: "soft_redirect",
            safe_rewrite: "Turn the event into a supportive learning moment where the child understands the mistake and receives help.",
            applies_to: ["3-5", "6-8", "9-11"]
        ),
        RedirectRule(
            id: "redirect_abandonment",
            trigger_terms: ["child alone in the dark", "no one helps", "abandoned"],
            strategy: "soft_redirect",
            safe_rewrite: "Allow a brief moment of uncertainty, then quickly introduce safety, help, comfort, and reunion.",
            applies_to: ["3-5", "6-8", "9-11"]
        ),
        RedirectRule(
            id: "redirect_graveyard",
            trigger_terms: ["graveyard", "cemetery", "ghost attack"],
            strategy: "soft_redirect",
            safe_rewrite: "Convert the setting into a gentle nighttime mystery with moonlight, fireflies, soft sounds, and a fully safe atmosphere.",
            applies_to: ["6-8", "9-11"]
        )
    ]

    // Hard / soft term list for quick scanning (programmatic kullanım)
    static let hardBlockTerms: [String] = [
        "kill", "murder", "death", "corpse", "grave", "blood", "drowning",
        "kidnapping", "torture", "suicide", "self-harm", "demon", "satan",
        "ritual", "stabbing", "shooting", "massacre", "rape", "sexual content",
        "dismemberment", "gore"
    ]

    static let softRedirectTerms: [String] = [
        "very scary", "terrifying", "extremely dark", "make the child cry",
        "punish the child", "revenge", "everyone is angry at the child",
        "monster chasing", "witch takes the child", "haunted graveyard",
        "ghost attacks", "nightmare creature", "child gets lost alone",
        "trapped in darkness", "no one helps"
    ]
}

