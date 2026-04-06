import { supabaseAdmin } from "../../config/supabase";

export type SubscriptionPlan = "free" | "premium";
export type SubscriptionStatus = "active" | "inactive";

export type SubscriptionRow = {
  id: string;
  user_id: string;
  status: SubscriptionStatus | string;
  plan: SubscriptionPlan | string;
  current_period_end: string | null;
  created_at?: string;
};

export type SubscriptionStatusResponse = {
  plan: SubscriptionPlan;
  status: SubscriptionStatus;
  currentPeriodEnd: string | null;
};

class SubscriptionService {
  async getSubscriptionStatus(userId: string): Promise<SubscriptionStatusResponse> {
    const { data, error } = await supabaseAdmin
      .from("subscriptions")
      .select("plan,status,current_period_end")
      .eq("user_id", userId)
      .order("current_period_end", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;

    if (!data) {
      return { plan: "free", status: "inactive", currentPeriodEnd: null };
    }

    const row = data as unknown as SubscriptionRow;

    const planRaw = String(row.plan).toLowerCase();
    const statusRaw = String(row.status).toLowerCase();

    const status: SubscriptionStatus = statusRaw === "active" ? "active" : "inactive";
    const candidatePlan: SubscriptionPlan = planRaw === "premium" ? "premium" : "free";

    // If current period end is provided, ensure it hasn't expired.
    if (candidatePlan === "premium" && row.current_period_end) {
      const end = new Date(row.current_period_end ?? undefined);
      if (!Number.isNaN(end.getTime()) && end.getTime() <= Date.now()) {
        return { plan: "free", status: "inactive", currentPeriodEnd: row.current_period_end };
      }
    }

    if (candidatePlan === "premium" && status !== "active") {
      return { plan: "free", status: "inactive", currentPeriodEnd: row.current_period_end };
    }

    // Basic/beginning mock: rely on plan/status/current_period_end.
    return { plan: candidatePlan, status, currentPeriodEnd: row.current_period_end };
  }

  // Helper for business logic.
  isPremium(plan: SubscriptionPlan): boolean {
    return plan === "premium";
  }

  // Optional: validate admin-only actions later.
  // (No admin write endpoints yet in this skeleton.)
  assertUserExists(_userId: string): void {
    // Intentionally no-op for now.
  }
}

export const subscriptionService = new SubscriptionService();

