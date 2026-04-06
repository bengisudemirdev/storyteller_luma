"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.subscriptionService = void 0;
const supabase_1 = require("../../config/supabase");
class SubscriptionService {
    async getSubscriptionStatus(userId) {
        const { data, error } = await supabase_1.supabaseAdmin
            .from("subscriptions")
            .select("plan,status,current_period_end")
            .eq("user_id", userId)
            .order("current_period_end", { ascending: false })
            .limit(1)
            .maybeSingle();
        if (error)
            throw error;
        if (!data) {
            return { plan: "free", status: "inactive", currentPeriodEnd: null };
        }
        const row = data;
        const planRaw = String(row.plan).toLowerCase();
        const statusRaw = String(row.status).toLowerCase();
        const status = statusRaw === "active" ? "active" : "inactive";
        const candidatePlan = planRaw === "premium" ? "premium" : "free";
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
    isPremium(plan) {
        return plan === "premium";
    }
    // Optional: validate admin-only actions later.
    // (No admin write endpoints yet in this skeleton.)
    assertUserExists(_userId) {
        // Intentionally no-op for now.
    }
}
exports.subscriptionService = new SubscriptionService();
//# sourceMappingURL=subscription.service.js.map