"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.childrenService = void 0;
exports.normalizeChildRow = normalizeChildRow;
const supabase_1 = require("../../config/supabase");
const apiError_1 = require("../../utils/apiError");
function coerceStringArray(v) {
    if (Array.isArray(v)) {
        return v.map((x) => String(x)).filter((s) => s.length > 0);
    }
    if (typeof v === "string") {
        const s = v.trim();
        if (s.startsWith("{") && s.endsWith("}")) {
            const inner = s.slice(1, -1).trim();
            if (!inner)
                return [];
            return inner
                .split(",")
                .map((part) => part.replace(/^"(.*)"$/, "$1").trim())
                .filter(Boolean);
        }
    }
    return [];
}
/** Normalizes DB rows (e.g. before migration or null arrays). */
function normalizeChildRow(raw) {
    const r = raw;
    return {
        id: String(r.id),
        user_id: String(r.user_id),
        name: String(r.name),
        age: typeof r.age === "number" ? r.age : r.age == null ? null : Number(r.age),
        profile: r.profile == null ? null : String(r.profile),
        avatar_emoji: typeof r.avatar_emoji === "string" && r.avatar_emoji.trim() ? r.avatar_emoji : "🦊",
        interests: coerceStringArray(r.interests),
        fears: coerceStringArray(r.fears),
        created_at: r.created_at != null ? String(r.created_at) : undefined,
        updated_at: r.updated_at != null ? String(r.updated_at) : undefined
    };
}
class ChildrenService {
    async createChild(input) {
        const { userId, name, age, profile, avatar_emoji, interests, fears } = input;
        const emoji = (avatar_emoji ?? "🦊").trim() || "🦊";
        const interestList = Array.isArray(interests) ? interests : [];
        const fearList = Array.isArray(fears) ? fears : [];
        const { data, error } = await supabase_1.supabaseAdmin
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
        if (error || !data)
            throw error ?? new apiError_1.ApiError(500, "CHILD_CREATE_FAILED", "Failed to create child");
        return normalizeChildRow(data);
    }
    async listChildren(userId) {
        const { data, error } = await supabase_1.supabaseAdmin
            .from("children")
            .select("*")
            .eq("user_id", userId)
            .order("created_at", { ascending: false });
        if (error)
            throw error;
        return (data ?? []).map((row) => normalizeChildRow(row));
    }
    async getChildForUser(userId, childId) {
        const { data, error } = await supabase_1.supabaseAdmin
            .from("children")
            .select("*")
            .eq("user_id", userId)
            .eq("id", childId)
            .maybeSingle();
        if (error)
            throw error;
        if (!data)
            throw new apiError_1.ApiError(404, "CHILD_NOT_FOUND", "Child not found");
        return normalizeChildRow(data);
    }
    async updateChildForUser(userId, childId, patch) {
        const payload = {};
        if (patch.name !== undefined)
            payload.name = patch.name;
        if (patch.age !== undefined)
            payload.age = patch.age;
        if (patch.profile !== undefined)
            payload.profile = patch.profile;
        if (patch.avatar_emoji !== undefined) {
            const e = (patch.avatar_emoji ?? "🦊").trim() || "🦊";
            payload.avatar_emoji = e;
        }
        if (patch.interests !== undefined)
            payload.interests = Array.isArray(patch.interests) ? patch.interests : [];
        if (patch.fears !== undefined)
            payload.fears = Array.isArray(patch.fears) ? patch.fears : [];
        const { data, error } = await supabase_1.supabaseAdmin
            .from("children")
            .update(payload)
            .eq("user_id", userId)
            .eq("id", childId)
            .select("*")
            .maybeSingle();
        if (error)
            throw error;
        if (!data)
            throw new apiError_1.ApiError(404, "CHILD_NOT_FOUND", "Child not found");
        return normalizeChildRow(data);
    }
    async deleteChildForUser(userId, childId) {
        const { data, error } = await supabase_1.supabaseAdmin
            .from("children")
            .delete()
            .eq("user_id", userId)
            .eq("id", childId)
            .select("*")
            .maybeSingle();
        if (error)
            throw error;
        if (!data)
            throw new apiError_1.ApiError(404, "CHILD_NOT_FOUND", "Child not found");
        return normalizeChildRow(data);
    }
}
exports.childrenService = new ChildrenService();
//# sourceMappingURL=children.service.js.map