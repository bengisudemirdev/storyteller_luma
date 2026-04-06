"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseLegacyProfile = parseLegacyProfile;
exports.resolveChildFieldsForPrompt = resolveChildFieldsForPrompt;
const promptSanitizer_1 = require("./promptSanitizer");
/**
 * Parses legacy `profile` strings like:
 * `emoji:🦊 | interests:a, b | fears:x`
 */
function parseLegacyProfile(profile) {
    const empty = { emoji: null, interests: [], fears: [], remainder: null };
    if (!profile || !profile.trim())
        return empty;
    const segments = profile.split("|").map((s) => s.trim()).filter(Boolean);
    const loose = [];
    let emoji = null;
    const interests = [];
    const fears = [];
    for (const seg of segments) {
        const lower = seg.toLowerCase();
        if (lower.startsWith("emoji:")) {
            const v = seg.slice(seg.indexOf(":") + 1).trim();
            if (v)
                emoji = v;
            continue;
        }
        if (lower.startsWith("interests:")) {
            const v = seg.slice(seg.indexOf(":") + 1).trim();
            if (v) {
                v.split(",").forEach((x) => {
                    const t = x.trim();
                    if (t)
                        interests.push(t);
                });
            }
            continue;
        }
        if (lower.startsWith("fears:")) {
            const v = seg.slice(seg.indexOf(":") + 1).trim();
            if (v) {
                v.split(",").forEach((x) => {
                    const t = x.trim();
                    if (t)
                        fears.push(t);
                });
            }
            continue;
        }
        loose.push(seg);
    }
    const remainder = loose.length ? loose.join(" | ") : null;
    return { emoji, interests, fears, remainder };
}
function normalizeStringArray(v) {
    if (!v || !Array.isArray(v))
        return [];
    return v.map((s) => String(s).trim()).filter(Boolean);
}
const DEFAULT_EMOJI = "🦊";
/**
 * Merges DB columns with legacy `profile` when columns are still empty / default (pre-migration data).
 */
function resolveChildFieldsForPrompt(child) {
    const parsed = parseLegacyProfile(child.profile);
    const dbInterests = normalizeStringArray(child.interests);
    const dbFears = normalizeStringArray(child.fears);
    const dbEmoji = (child.avatar_emoji ?? DEFAULT_EMOJI).trim() || DEFAULT_EMOJI;
    let interests = dbInterests.length ? dbInterests : parsed.interests;
    let fears = dbFears.length ? dbFears : parsed.fears;
    let avatarEmoji = dbEmoji;
    if (dbEmoji === DEFAULT_EMOJI && parsed.emoji) {
        avatarEmoji = parsed.emoji;
    }
    interests = interests.map((s) => (0, promptSanitizer_1.sanitizeForPrompt)(s, 80)).filter(Boolean);
    fears = fears.map((s) => (0, promptSanitizer_1.sanitizeForPrompt)(s, 80)).filter(Boolean);
    avatarEmoji = (0, promptSanitizer_1.sanitizeForPrompt)(avatarEmoji, 16) || DEFAULT_EMOJI;
    const legacyRemainder = parsed.remainder ? (0, promptSanitizer_1.sanitizeForPrompt)(parsed.remainder, 300) : null;
    return { avatarEmoji, interests, fears, legacyRemainder };
}
//# sourceMappingURL=childPromptContext.js.map