"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.THEME_ALLOWLIST = void 0;
exports.normalizeTheme = normalizeTheme;
exports.assertThemeAllowed = assertThemeAllowed;
const apiError_1 = require("../utils/apiError");
// Keep this conservative to reduce unwanted or unsafe themes.
// You can extend this list once your moderation strategy is in place.
exports.THEME_ALLOWLIST = [
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
];
function normalizeTheme(input) {
    return input
        .trim()
        .toLocaleLowerCase("tr")
        .replace(/\s+/g, " ");
}
function assertThemeAllowed(input) {
    const normalized = normalizeTheme(input);
    const allowed = exports.THEME_ALLOWLIST.includes(normalized);
    if (!allowed) {
        throw apiError_1.ApiError.badRequest("THEME_NOT_ALLOWED", "Selected theme is not allowed. Please choose a permitted theme.");
    }
    return normalized;
}
//# sourceMappingURL=themeWhitelist.js.map