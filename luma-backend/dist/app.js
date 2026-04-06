"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.app = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const env_1 = require("./config/env");
const rateLimit_middleware_1 = require("./middlewares/rateLimit.middleware");
const error_middleware_1 = require("./middlewares/error.middleware");
const auth_routes_1 = require("./modules/auth/auth.routes");
const children_routes_1 = require("./modules/children/children.routes");
const stories_routes_1 = require("./modules/stories/stories.routes");
const usage_routes_1 = require("./modules/usage/usage.routes");
const subscription_routes_1 = require("./modules/subscription/subscription.routes");
const apiError_1 = require("./utils/apiError");
const swagger_1 = require("./config/swagger");
const requestContext_middleware_1 = require("./middlewares/requestContext.middleware");
exports.app = (0, express_1.default)();
exports.app.disable("x-powered-by");
if (env_1.env.TRUST_PROXY) {
    exports.app.set("trust proxy", 1);
}
exports.app.get("/", (_req, res) => {
    res.status(200).json({
        success: true,
        data: {
            service: "luma-backend",
            health: "/v1/health",
            docs: env_1.env.SWAGGER_ENABLED ? "/docs" : null
        }
    });
});
exports.app.use((0, helmet_1.default)({
    // API server; keep security headers without enforcing browser-specific CSP.
    contentSecurityPolicy: false
}));
const allowedOrigins = env_1.env.CORS_ORIGINS;
exports.app.use((0, cors_1.default)({
    origin: (origin, callback) => {
        // Mobile apps might not send Origin; allow those.
        if (!origin)
            return callback(null, true);
        if (allowedOrigins.length === 0)
            return callback(null, true);
        if (allowedOrigins.includes(origin))
            return callback(null, true);
        return callback(new apiError_1.ApiError(403, "CORS_FORBIDDEN", "Origin not allowed"));
    },
    credentials: false
}));
exports.app.use(requestContext_middleware_1.requestContextMiddleware);
exports.app.use(express_1.default.json({ limit: env_1.env.JSON_BODY_LIMIT }));
exports.app.use((0, morgan_1.default)(env_1.env.LOG_FORMAT));
// Health endpoint (not part of your required list, safe to keep).
exports.app.get("/v1/health", (_req, res) => {
    res.status(200).json({ success: true, data: { ok: true } });
});
// Rate limit for everything under /v1.
exports.app.use("/v1", rateLimit_middleware_1.v1RateLimiter);
// Extra stricter limiter for story generation endpoint.
exports.app.use("/v1/stories/generate", rateLimit_middleware_1.storiesGenerateRateLimiter);
// Routes
exports.app.use("/v1/auth", auth_routes_1.authRoutes);
exports.app.use("/v1/children", children_routes_1.childrenRoutes);
exports.app.use("/v1/stories", stories_routes_1.storiesRoutes);
exports.app.use("/v1/usage", usage_routes_1.usageRoutes);
exports.app.use("/v1/subscription", subscription_routes_1.subscriptionRoutes);
// OpenAPI docs (Basic-auth protected).
if (env_1.env.SWAGGER_ENABLED) {
    exports.app.use("/docs", swagger_1.swaggerBasicAuthMiddleware, swagger_1.swaggerUi.serve, swagger_1.swaggerUi.setup(swagger_1.swaggerSpec));
}
// 404 handler
exports.app.use((req, _res, next) => {
    next(new apiError_1.ApiError(404, "NOT_FOUND", `Route not found: ${req.method} ${req.path}`));
});
exports.app.use(error_middleware_1.errorMiddleware);
//# sourceMappingURL=app.js.map