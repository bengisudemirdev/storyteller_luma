"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAdmin = void 0;
const env_1 = require("../config/env");
const apiError_1 = require("../utils/apiError");
const requireAdmin = (req, _res, next) => {
    const email = req.user?.email;
    if (!email) {
        throw new apiError_1.ApiError(403, "FORBIDDEN", "Admin access required");
    }
    if (env_1.env.ADMIN_EMAILS.length === 0) {
        // No admins configured => deny by default to stay safe.
        throw new apiError_1.ApiError(403, "FORBIDDEN", "Admin access is not configured");
    }
    if (!env_1.env.ADMIN_EMAILS.includes(email)) {
        throw new apiError_1.ApiError(403, "FORBIDDEN", "Admin access required");
    }
    return next();
};
exports.requireAdmin = requireAdmin;
//# sourceMappingURL=requireAdmin.middleware.js.map