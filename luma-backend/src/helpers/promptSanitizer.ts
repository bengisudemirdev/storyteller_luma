function clamp(input: string, maxLen: number): string {
  const trimmed = input.trim();
  if (trimmed.length <= maxLen) return trimmed;
  return trimmed.slice(0, maxLen).trim();
}

export function sanitizeForPrompt(input: string, maxLen: number): string {
  const withoutControlChars = input
    .replace(/[\u0000-\u001F\u007F]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  return clamp(withoutControlChars, maxLen);
}

// Escape user-provided strings when embedding into quoted "literals".
// Prevents accidental delimiter injection and keeps the prompt deterministic.
export function escapeForQuotedLiteral(input: string): string {
  return input
    .replace(/\\/g, "\\\\")
    .replace(/"""/g, '""');
}

export function sanitizeModelOutputText(input: string, maxLen: number): string {
  const removedUrls = input.replace(/https?:\/\/\S+/g, "[link_removed]");
  const removedEmails = removedUrls.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[email_removed]");
  const noCodeFences = removedEmails.replace(/```[\s\S]*?```/g, "[code_block_removed]");
  return clamp(noCodeFences, maxLen);
}

/** Satır başı "1.", "2)" vb. paragraf numaralandırmasını kaldırır; düz anlatı metni kalır. */
export function stripStoryParagraphNumbering(story: string): string {
  return story.replace(/(^|\n)(\s*)\d{1,3}(?:\.\s+|\)\s+)/g, "$1$2");
}

