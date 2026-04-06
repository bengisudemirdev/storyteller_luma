"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiError = void 0;
class ApiError extends Error {
    constructor(statusCode, code, message, details) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
        // Fix prototype chain when targeting ES5 (safe here, harmless otherwise).
        Object.setPrototypeOf(this, ApiError.prototype);
    }
    static badRequest(code, message, details) {
        return new ApiError(400, code, message, details);
    }
    static unauthorized(code, message, details) {
        return new ApiError(401, code, message, details);
    }
    static forbidden(code, message, details) {
        return new ApiError(403, code, message, details);
    }
    static notFound(code, message, details) {
        return new ApiError(404, code, message, details);
    }
    static tooManyRequests(code, message, details) {
        return new ApiError(429, code, message, details);
    }
}
exports.ApiError = ApiError;
//# sourceMappingURL=apiError.js.map