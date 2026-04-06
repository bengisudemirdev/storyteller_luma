"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = void 0;
const supabase_1 = require("../config/supabase");
const apiError_1 = require("../utils/apiError");
const asyncHandler_1 = require("../utils/asyncHandler");
const auth_service_1 = require("../modules/auth/auth.service");
function extractBearerToken(req) {
    const header = req.headers.authorization;
    if (!header || typeof header !== "string")
        return null;
    const trimmed = header.trim();
    const m = /^Bearer\s+(.+)$/i.exec(trimmed);
    if (!m)
        return null;
    const token = m[1].trim();
    return token.length > 0 ? token : null;
}
exports.requireAuth = (0, asyncHandler_1.asyncHandler)(async (req, _res, next) => {
    const token = extractBearerToken(req);
    if (!token) {
        throw apiError_1.ApiError.unauthorized("MISSING_BEARER_TOKEN", "Missing Bearer token");
    }
    const { data, error } = await supabase_1.supabaseAdmin.auth.getUser(token);
    if (error || !data?.user) {
        if (process.env.NODE_ENV !== "production") {
            // Token asla loglanmaz; Supabase hata mesajı projeyi hizalamak için yeterli ipucu verir.
            console.warn("[requireAuth] supabase.auth.getUser failed:", error?.message ?? "no user");
        }
        throw apiError_1.ApiError.unauthorized("INVALID_TOKEN", "Invalid or expired token");
    }
    const user = {
        id: data.user.id,
        email: data.user.email
    };
    // Ensure app profile row exists (parents table) for future queries.
    await auth_service_1.authService.ensureUserRow(user);
    req.user = user;
    return next();
});
//# sourceMappingURL=auth.middleware.js.map