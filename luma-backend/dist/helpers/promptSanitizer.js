"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sanitizeForPrompt = sanitizeForPrompt;
exports.escapeForQuotedLiteral = escapeForQuotedLiteral;
exports.sanitizeModelOutputText = sanitizeModelOutputText;
function clamp(input, maxLen) {
    const trimmed = input.trim();
    if (trimmed.length <= maxLen)
        return trimmed;
    return trimmed.slice(0, maxLen).trim();
}
function sanitizeForPrompt(input, maxLen) {
    const withoutControlChars = input
        .replace(/[\u0000-\u001F\u007F]/g, " ")
        .replace(/\s+/g, " ")
        .trim();
    return clamp(withoutControlChars, maxLen);
}
// Escape user-provided strings when embedding into quoted "literals".
// Prevents accidental delimiter injection and keeps the prompt deterministic.
function escapeForQuotedLiteral(input) {
    return input
        .replace(/\\/g, "\\\\")
        .replace(/"""/g, '""');
}
function sanitizeModelOutputText(input, maxLen) {
    const removedUrls = input.replace(/https?:\/\/\S+/g, "[link_removed]");
    const removedEmails = removedUrls.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[email_removed]");
    const noCodeFences = removedEmails.replace(/```[\s\S]*?```/g, "[code_block_removed]");
    return clamp(noCodeFences, maxLen);
}
//# sourceMappingURL=promptSanitizer.js.map