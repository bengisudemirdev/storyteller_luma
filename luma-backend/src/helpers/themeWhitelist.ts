import { ApiError } from "../utils/apiError";

// Keep this conservative to reduce unwanted or unsafe themes.
// You can extend this list once your moderation strategy is in place.
export const THEME_ALLOWLIST = [
  "hayvanlar",
  "gizli bahce",
  "peri masallari",
  "uzay",
  "deniz",
  "denizaltı",
  "deniz alti",
  "dinozorlar",
  "ejderhalar",
  "korsanlar",
  "kale",
  "orman",
  "kış",
  "bahar",
  "yaz",
  "sonbahar",
  "kar",
  "yağmur",
  "büyü",
  "kahramanlar",
  "arkadaşlık",
  "dostluk",
  "cesaret",
  "paylaşma",
  "yardımlaşma",
  "umut",
  "mutluluk",
  "sevgi",
  "saygı",
  "adventure",
  "space",
  "animals",
  "forest",
  "ocean",
  "dragon",
  "wizard",
  "pirates"
] as const;

export type Theme = (typeof THEME_ALLOWLIST)[number];

export function normalizeTheme(input: string): string {
  return input
    .trim()
    .toLocaleLowerCase("tr")
    .replace(/\s+/g, " ");
}

export function assertThemeAllowed(input: string): Theme {
  const normalized = normalizeTheme(input);
  const allowed = (THEME_ALLOWLIST as ReadonlyArray<string>).includes(normalized);
  if (!allowed) {
    throw ApiError.badRequest(
      "THEME_NOT_ALLOWED",
      "Selected theme is not allowed. Please choose a permitted theme."
    );
  }

  return normalized as Theme;
}

