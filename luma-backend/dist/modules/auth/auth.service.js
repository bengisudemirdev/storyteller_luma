"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authService = void 0;
const supabase_1 = require("../../config/supabase");
const postgrestError_1 = require("../../utils/postgrestError");
class AuthService {
    async ensureUserRow(user) {
        // Keep backend app-specific user profile in sync with Supabase Auth.
        const email = user.email ?? null;
        const { error: parentsError } = await supabase_1.supabaseAdmin
            .from("parents")
            .upsert({ id: user.id, email }, { onConflict: "id" });
        if (!parentsError)
            return;
        // Eski Supabase projelerinde tablo adı hâlâ public.users olabilir (005 migration öncesi).
        if ((0, postgrestError_1.shouldFallbackParentsUpsertToUsersTable)(parentsError)) {
            const { error: usersError } = await supabase_1.supabaseAdmin
                .from("users")
                .upsert({ id: user.id, email }, { onConflict: "id" });
            if (usersError)
                throw usersError;
            return;
        }
        throw parentsError;
    }
    getMe(user) {
        return {
            user: {
                id: user.id,
                email: user.email ?? null
            }
        };
    }
}
exports.authService = new AuthService();
//# sourceMappingURL=auth.service.js.map