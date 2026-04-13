"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.storiesGenerateRateLimiter = exports.v1RateLimiter = void 0;
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const env_1 = require("../config/env");
const apiResponse_1 = require("../utils/apiResponse");
function isV1HealthCheck(req) {
    if (req.method !== "GET")
        return false;
    const path = (req.originalUrl ?? "").split("?")[0] ?? "";
    return path === "/v1/health";
}
function jsonRateLimitHandler(req, res) {
    res.status(429).json((0, apiResponse_1.toError)("RATE_LIMITED", "Rate limit exceeded", {
        method: req.method,
        path: req.originalUrl,
        ip: req.ip
    }));
}
exports.v1RateLimiter = (0, express_rate_limit_1.default)({
    windowMs: env_1.env.RATE_LIMIT_WINDOW_MS,
    limit: env_1.env.RATE_LIMIT_MAX,
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => env_1.env.RATE_LIMIT_DISABLED || isV1HealthCheck(req),
    handler: (req, res) => {
        jsonRateLimitHandler(req, res);
    },
    keyGenerator: (req) => {
        // Authenticated users share a limiter by IP to keep implementation simple.
        // If you want per-user rate limiting, you can key off the Bearer token claim after validation.
        return req.ip ?? "unknown";
    }
});
exports.storiesGenerateRateLimiter = (0, express_rate_limit_1.default)({
    windowMs: env_1.env.STORIES_GENERATE_RATE_LIMIT_WINDOW_MS,
    limit: env_1.env.STORIES_GENERATE_RATE_LIMIT_MAX,
    standardHeaders: true,
    legacyHeaders: false,
    skip: () => env_1.env.RATE_LIMIT_DISABLED,
    handler: (req, res) => {
        jsonRateLimitHandler(req, res);
    },
    keyGenerator: (req) => req.ip ?? "unknown"
});
//# sourceMappingURL=rateLimit.middleware.js.map