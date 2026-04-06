"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestContextMiddleware = void 0;
const crypto_1 = require("crypto");
/**
 * Her isteğe requestId atar (X-Request-Id header veya yeni UUID) ve yanıta yazar.
 */
const requestContextMiddleware = (req, res, next) => {
    const fromHeader = req.headers["x-request-id"];
    const id = typeof fromHeader === "string" && fromHeader.trim().length > 0 ? fromHeader.trim() : (0, crypto_1.randomUUID)();
    req.requestId = id;
    res.setHeader("x-request-id", id);
    next();
};
exports.requestContextMiddleware = requestContextMiddleware;
//# sourceMappingURL=requestContext.middleware.js.map