import { ApiError } from "../utils/apiError";

const PROMPT_INJECTION_TOKENS = [
  "ignore previous",
  "ignore instructions",
  "system:",
  "developer:",
  "assistant:",
  "user:",
  "role:",
  "do anything now",
  "pretend",
  "reveal",
  "instruction",
  "prompt",
  "function call"
];

const UNSAFE_OUTPUT_KEYWORDS = [
  "kan",
  "öldür",
  "cinayet",
  "intihar",
  "tecavüz",
  "porn",
  "seks",
  "çıplak",
  "uyuşturucu",
  "silah",
  "bomb",
  "şiddet",
  "yetişkin"
];

const UNSAFE_INPUT_KEYWORDS = [
  "ölüm",
  "öldür",
  "cinayet",
  "intihar",
  "tecavüz",
  "porn",
  "seks",
  "uyuşturucu",
  "şiddet",
  "bomb"
];

function normalizeText(input: string): string {
  return input.trim().toLocaleLowerCase("tr");
}

function containsAnyToken(haystack: string, tokens: ReadonlyArray<string>): boolean {
  return tokens.some((t) => haystack.includes(t));
}

export function preModerateStoryInputs(input: {
  theme: string;
  childName: string;
  /** Legacy blob; still moderated when present */
  childProfile?: string | null;
  childAvatarEmoji?: string | null;
  childInterests?: string[];
  childFears?: string[];
  extraContext?: string | null;
  selectedInterests?: string[];
  storyGoal?: string | null;
  tonePreference?: string | null;
  lengthPreference?: string | null;
}): void {
  const full = normalizeText(
    [
      input.theme,
      input.childName,
      input.childProfile ?? "",
      input.childAvatarEmoji ?? "",
      input.extraContext ?? "",
      input.storyGoal ?? "",
      input.tonePreference ?? "",
      input.lengthPreference ?? "",
      ...(input.childInterests ?? []),
      ...(input.childFears ?? []),
      ...(input.selectedInterests ?? [])
    ].join(" | ")
  );

  if (containsAnyToken(full, PROMPT_INJECTION_TOKENS)) {
    throw ApiError.badRequest("INPUT_UNSAFE", "Story input contains unsafe instructions.");
  }

  if (containsAnyToken(full, UNSAFE_INPUT_KEYWORDS)) {
    throw ApiError.badRequest("INPUT_UNSAFE", "Story input contains unsafe content.");
  }
}

export function moderateStoryOutputText(storyText: string): void {
  const t = normalizeText(storyText);
  if (containsAnyToken(t, UNSAFE_OUTPUT_KEYWORDS)) {
    throw new ApiError(
      400,
      "CONTENT_UNSAFE",
      "Generated story includes unsafe content. Please try another theme/child."
    );
  }
}

