import { supabaseAdmin } from "../../config/supabase";
import { env } from "../../config/env";
import { ApiError } from "../../utils/apiError";
import type { SubscriptionPlan } from "../subscription/subscription.service";

export type UsageType = "story_generate";

export type UsageLogRow = {
  id: string;
  user_id: string;
  date: string; // YYYY-MM-DD
  usage_type: UsageType;
  count: number;
  plan: SubscriptionPlan;
  created_at?: string;
};

export type DailyUsage = {
  date: string;
  plan: SubscriptionPlan;
  used: number;
  limit: number;
  remaining: number;
};

function getTodayUTCString(): string {
  const now = new Date();
  const yyyy = String(now.getUTCFullYear());
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(now.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function getDailyLimit(plan: SubscriptionPlan): number {
  return plan === "premium" ? env.DAILY_PREMIUM_STORY_LIMIT : env.DAILY_FREE_STORY_LIMIT;
}

class UsageService {
  async getDailyUsage(userId: string, plan: SubscriptionPlan): Promise<DailyUsage> {
    const today = getTodayUTCString();
    const limit = getDailyLimit(plan);

    const { data, error } = await supabaseAdmin
      .from("usage_logs")
      .select("count,plan")
      .eq("user_id", userId)
      .eq("date", today)
      .eq("usage_type", "story_generate")
      .maybeSingle();

    if (error) throw error;

    const row = data as unknown as { count?: number | null } | null | undefined;
    const used = row?.count ?? 0;
    return {
      date: today,
      plan,
      used,
      limit,
      remaining: Math.max(0, limit - used)
    };
  }

  private getTodayUTCStringForReserve(): string {
    return getTodayUTCString();
  }

  async reserveStoryGenerateUsageAtomic(input: {
    userId: string;
    plan: SubscriptionPlan;
    amount?: number;
    limit?: number;
    dateOverride?: string;
  }): Promise<DailyUsage> {
    const amount = input.amount ?? 1;
    if (amount <= 0) throw ApiError.badRequest("INVALID_AMOUNT", "Amount must be positive");

    const date = input.dateOverride ?? this.getTodayUTCStringForReserve();
    const limit = input.limit ?? getDailyLimit(input.plan);

    type ReserveRow = { allowed: boolean; new_count: number; remaining: number };

    const { data, error } = await supabaseAdmin.rpc("reserve_story_generate_usage", {
      p_user_id: input.userId,
      p_date: date,
      p_plan: input.plan,
      p_amount: amount,
      p_limit: limit
    });

    if (error) {
      throw new ApiError(500, "USAGE_RESERVE_FAILED", "Failed to reserve usage");
    }

    const rows = data as unknown as Array<ReserveRow> | ReserveRow | null | undefined;
    const row = Array.isArray(rows) ? rows[0] : rows;

    if (!row) throw new ApiError(500, "USAGE_RESERVE_FAILED", "Invalid reserve response");
    if (!row.allowed) {
      throw ApiError.tooManyRequests("DAILY_LIMIT_REACHED", "Daily story limit reached", {
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

  async releaseStoryGenerateUsageAtomic(input: {
    userId: string;
    amount?: number;
    dateOverride?: string;
  }): Promise<void> {
    const amount = input.amount ?? 1;
    if (amount <= 0) return;

    const date = input.dateOverride ?? getTodayUTCString();

    const { error } = await supabaseAdmin.rpc("release_story_generate_usage", {
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

export const usageService = new UsageService();

