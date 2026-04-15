import { supabaseAdmin } from "../../config/supabase";
import { ApiError } from "../../utils/apiError";

export type ChildRow = {
  id: string;
  user_id: string;
  name: string;
  age: number | null;
  profile: string | null;
  avatar_emoji: string;
  interests: string[];
  fears: string[];
  created_at?: string;
  updated_at?: string;
};

type CreateChildInput = {
  userId: string;
  name: string;
  age?: number | null;
  profile?: string | null;
  avatar_emoji?: string | null;
  interests?: string[] | null;
  fears?: string[] | null;
};

type UpdateChildPatch = {
  name?: string;
  age?: number | null;
  profile?: string | null;
  avatar_emoji?: string | null;
  interests?: string[] | null;
  fears?: string[] | null;
};

const DEFAULT_AVATAR_EMOJI = "🦊";

function coerceStringArray(v: unknown): string[] {
  if (Array.isArray(v)) {
    return (v as unknown[]).map((x) => String(x)).filter((s) => s.length > 0);
  }
  if (typeof v === "string") {
    const s = v.trim();
    if (s.startsWith("{") && s.endsWith("}")) {
      const inner = s.slice(1, -1).trim();
      if (!inner) return [];
      return inner
        .split(",")
        .map((part) => part.replace(/^"(.*)"$/, "$1").trim())
        .filter(Boolean);
    }
  }
  return [];
}

function normalizeAvatarEmoji(raw: unknown): string {
  if (typeof raw !== "string") return DEFAULT_AVATAR_EMOJI;
  const trimmed = raw.trim();
  if (!trimmed) return DEFAULT_AVATAR_EMOJI;
  if (trimmed === "?" || trimmed.includes("\uFFFD")) return DEFAULT_AVATAR_EMOJI;
  return Array.from(trimmed)[0] ?? DEFAULT_AVATAR_EMOJI;
}

/** Normalizes DB rows (e.g. before migration or null arrays). */
export function normalizeChildRow(raw: unknown): ChildRow {
  const r = raw as Record<string, unknown>;
  return {
    id: String(r.id),
    user_id: String(r.user_id),
    name: String(r.name),
    age: typeof r.age === "number" ? r.age : r.age == null ? null : Number(r.age),
    profile: r.profile == null ? null : String(r.profile),
    avatar_emoji: normalizeAvatarEmoji(r.avatar_emoji),
    interests: coerceStringArray(r.interests),
    fears: coerceStringArray(r.fears),
    created_at: r.created_at != null ? String(r.created_at) : undefined,
    updated_at: r.updated_at != null ? String(r.updated_at) : undefined
  };
}

class ChildrenService {
  async createChild(input: CreateChildInput): Promise<ChildRow> {
    const { userId, name, age, profile, avatar_emoji, interests, fears } = input;

    const emoji = normalizeAvatarEmoji(avatar_emoji);
    const interestList = Array.isArray(interests) ? interests : [];
    const fearList = Array.isArray(fears) ? fears : [];

    const { data, error } = await supabaseAdmin
      .from("children")
      .insert({
        user_id: userId,
        name,
        age: age ?? null,
        profile: profile ?? null,
        avatar_emoji: emoji,
        interests: interestList,
        fears: fearList
      })
      .select("*")
      .single();

    if (error || !data) throw error ?? new ApiError(500, "CHILD_CREATE_FAILED", "Failed to create child");
    return normalizeChildRow(data);
  }

  async listChildren(userId: string): Promise<Array<ChildRow>> {
    const { data, error } = await supabaseAdmin
      .from("children")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data ?? []).map((row) => normalizeChildRow(row));
  }

  async getChildForUser(userId: string, childId: string): Promise<ChildRow> {
    const { data, error } = await supabaseAdmin
      .from("children")
      .select("*")
      .eq("user_id", userId)
      .eq("id", childId)
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new ApiError(404, "CHILD_NOT_FOUND", "Child not found");
    return normalizeChildRow(data);
  }

  async updateChildForUser(userId: string, childId: string, patch: UpdateChildPatch): Promise<ChildRow> {
    const payload: Record<string, unknown> = {};
    if (patch.name !== undefined) payload.name = patch.name;
    if (patch.age !== undefined) payload.age = patch.age;
    if (patch.profile !== undefined) payload.profile = patch.profile;
    if (patch.avatar_emoji !== undefined) {
      const e = normalizeAvatarEmoji(patch.avatar_emoji);
      payload.avatar_emoji = e;
    }
    if (patch.interests !== undefined) payload.interests = Array.isArray(patch.interests) ? patch.interests : [];
    if (patch.fears !== undefined) payload.fears = Array.isArray(patch.fears) ? patch.fears : [];

    const { data, error } = await supabaseAdmin
      .from("children")
      .update(payload)
      .eq("user_id", userId)
      .eq("id", childId)
      .select("*")
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new ApiError(404, "CHILD_NOT_FOUND", "Child not found");
    return normalizeChildRow(data);
  }

  async deleteChildForUser(userId: string, childId: string): Promise<ChildRow> {
    const { data, error } = await supabaseAdmin
      .from("children")
      .delete()
      .eq("user_id", userId)
      .eq("id", childId)
      .select("*")
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new ApiError(404, "CHILD_NOT_FOUND", "Child not found");
    return normalizeChildRow(data);
  }
}

export const childrenService = new ChildrenService();

