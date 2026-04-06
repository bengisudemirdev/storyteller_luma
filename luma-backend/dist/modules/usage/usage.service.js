"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.usageService = void 0;
const supabase_1 = require("../../config/supabase");
const env_1 = require("../../config/env");
const apiError_1 = require("../../utils/apiError");
function getTodayUTCString() {
    const now = new Date();
    const yyyy = String(now.getUTCFullYear());
    const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(now.getUTCDate()).padStart(2, "0");
    return `${yyyy}-${mm}-${dd}`;
}
function getDailyLimit(plan) {
    return plan === "premium" ? env_1.env.DAILY_PREMIUM_STORY_LIMIT : env_1.env.DAILY_FREE_STORY_LIMIT;
}
class UsageService {
    async getDailyUsage(userId, plan) {
        const today = getTodayUTCString();
        const limit = getDailyLimit(plan);
        const { data, error } = await supabase_1.supabaseAdmin
            .from("usage_logs")
            .select("count,plan")
            .eq("user_id", userId)
            .eq("date", today)
            .eq("usage_type", "story_generate")
            .maybeSingle();
        if (error)
            throw error;
        const row = data;
        const used = row?.count ?? 0;
        return {
            date: today,
            plan,
            used,
            limit,
            remaining: Math.max(0, limit - used)
        };
    }
    getTodayUTCStringForReserve() {
        return getTodayUTCString();
    }
    async reserveStoryGenerateUsageAtomic(input) {
        const amount = input.amount ?? 1;
        if (amount <= 0)
            throw apiError_1.ApiError.badRequest("INVALID_AMOUNT", "Amount must be positive");
        const date = input.dateOverride ?? this.getTodayUTCStringForReserve();
        const limit = input.limit ?? getDailyLimit(input.plan);
        const { data, error } = await supabase_1.supabaseAdmin.rpc("reserve_story_generate_usage", {
            p_user_id: input.userId,
            p_date: date,
            p_plan: input.plan,
            p_amount: amount,
            p_limit: limit
        });
        if (error) {
            throw new apiError_1.ApiError(500, "USAGE_RESERVE_FAILED", "Failed to reserve usage");
        }
        const rows = data;
        const row = Array.isArray(rows) ? rows[0] : rows;
        if (!row)
            throw new apiError_1.ApiError(500, "USAGE_RESERVE_FAILED", "Invalid reserve response");
        if (!row.allowed) {
            throw apiError_1.ApiError.tooManyRequests("DAILY_LIMIT_REACHED", "Daily story limit reached", {
                used: row.new_count,
                limit
            });
        }
        return {
            date,
            plan: input.plan,
            used: row.new_count,
            limit,
            remaining: row.remaining
        };
    }
    async releaseStoryGenerateUsageAtomic(input) {
        const amount = input.amount ?? 1;
        if (amount <= 0)
            return;
        const date = input.dateOverride ?? getTodayUTCString();
        const { error } = await supabase_1.supabaseAdmin.rpc("release_story_generate_usage", {
            p_user_id: input.userId,
            p_date: date,
            p_amount: amount
        });
        if (error) {
            // Best-effort: releasing usage should not break the request lifecycle.
            return;
        }
    }
}
exports.usageService = new UsageService();
//# sourceMappingURL=usage.service.js.map