import type { ChildRow } from "../modules/children/children.service";
import { sanitizeForPrompt } from "./promptSanitizer";

export type ParsedLegacyProfile = {
  emoji: string | null;
  interests: string[];
  fears: string[];
  /** Remaining free text after key:value segments (if any) */
  remainder: string | null;
};

/**
 * Parses legacy `profile` strings like:
 * `emoji:🦊 | interests:a, b | fears:x`
 */
export function parseLegacyProfile(profile: string | null | undefined): ParsedLegacyProfile {
  const empty: ParsedLegacyProfile = { emoji: null, interests: [], fears: [], remainder: null };
  if (!profile || !profile.trim()) return empty;

  const segments = profile.split("|").map((s) => s.trim()).filter(Boolean);
  const loose: string[] = [];

  let emoji: string | null = null;
  const interests: string[] = [];
  const fears: string[] = [];

  for (const seg of segments) {
    const lower = seg.toLowerCase();
    if (lower.startsWith("emoji:")) {
      const v = seg.slice(seg.indexOf(":") + 1).trim();
      if (v) emoji = v;
      continue;
    }
    if (lower.startsWith("interests:")) {
      const v = seg.slice(seg.indexOf(":") + 1).trim();
      if (v) {
        v.split(",").forEach((x) => {
          const t = x.trim();
          if (t) interests.push(t);
        });
      }
      continue;
    }
    if (lower.startsWith("fears:")) {
      const v = seg.slice(seg.indexOf(":") + 1).trim();
      if (v) {
        v.split(",").forEach((x) => {
          const t = x.trim();
          if (t) fears.push(t);
        });
      }
      continue;
    }
    loose.push(seg);
  }

  const remainder = loose.length ? loose.join(" | ") : null;
  return { emoji, interests, fears, remainder };
}

function normalizeStringArray(v: string[] | null | undefined): string[] {
  if (!v || !Array.isArray(v)) return [];
  return v.map((s) => String(s).trim()).filter(Boolean);
}

const DEFAULT_EMOJI = "🦊";

/**
 * Merges DB columns with legacy `profile` when columns are still empty / default (pre-migration data).
 */
export function resolveChildFieldsForPrompt(child: ChildRow): {
  avatarEmoji: string;
  interests: string[];
  fears: string[];
  /** Extra unstructured note (sanitized), only when present */
  legacyRemainder: string | null;
} {
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

  interests = interests.map((s) => sanitizeForPrompt(s, 80)).filter(Boolean);
  fears = fears.map((s) => sanitizeForPrompt(s, 80)).filter(Boolean);
  avatarEmoji = sanitizeForPrompt(avatarEmoji, 16) || DEFAULT_EMOJI;

  const legacyRemainder = parsed.remainder ? sanitizeForPrompt(parsed.remainder, 300) : null;

  return { avatarEmoji, interests, fears, legacyRemainder };
}
