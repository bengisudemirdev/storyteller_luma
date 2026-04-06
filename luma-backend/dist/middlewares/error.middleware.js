"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorMiddleware = errorMiddleware;
const zod_1 = require("zod");
const apiError_1 = require("../utils/apiError");
const apiResponse_1 = require("../utils/apiResponse");
const logger_1 = require("../utils/logger");
const postgrestError_1 = require("../utils/postgrestError");
function errorMiddleware(err, req, res, _next) {
    const requestId = req.requestId ?? req.headers["x-request-id"] ?? undefined;
    if (err instanceof apiError_1.ApiError) {
        logger_1.logger.error("API error:", {
            requestId,
            code: err.code,
            statusCode: err.statusCode,
            message: err.message
        });
        res.status(err.statusCode).json((0, apiResponse_1.toError)(err.code, err.message, {
            ...(err.details ? { details: err.details } : null),
            requestId
        }));
        return;
    }
    if (err instanceof zod_1.ZodError) {
        logger_1.logger.warn("Validation error:", {
            requestId,
            issues: err.issues
        });
        res.status(400).json((0, apiResponse_1.toError)("VALIDATION_ERROR", "Invalid request body", {
            issues: err.issues,
            requestId
        }));
        return;
    }
    const isProd = process.env.NODE_ENV === "production";
    const baseLog = {
        requestId,
        message: err instanceof Error ? err.message : "Unknown error",
        stack: err instanceof Error ? (isProd ? undefined : err.stack) : undefined
    };
    if ((0, postgrestError_1.isPostgrestLikeError)(err)) {
        baseLog.postgrestCode = err.code;
        if (err.details)
            baseLog.postgrestDetails = err.details;
        if (err.hint)
            baseLog.postgrestHint = err.hint;
    }
    logger_1.logger.error("Unhandled error:", baseLog);
    res.status(500).json((0, apiResponse_1.toError)("INTERNAL_SERVER_ERROR", "An unexpected error occurred", {
        requestId
    }));
}
//# sourceMappingURL=error.middleware.js.map