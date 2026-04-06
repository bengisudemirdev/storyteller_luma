"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRequestLogContext = getRequestLogContext;
/** Hassas header/body loglanmaz. */
function getRequestLogContext(req) {
    const ua = req.get("user-agent");
    return {
        requestId: req.requestId ?? null,
        method: req.method,
        path: req.originalUrl ?? req.url ?? "",
        userId: req.user?.id ?? null,
        ip: req.ip ?? null,
        userAgent: ua ? ua.slice(0, 160) : null
    };
}
//# sourceMappingURL=requestLogContext.js.map