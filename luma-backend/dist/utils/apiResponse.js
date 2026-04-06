"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toSuccess = toSuccess;
exports.toError = toError;
function toSuccess(data) {
    return { success: true, data };
}
function toError(code, message, details) {
    return { success: false, error: { code, message, details } };
}
//# sourceMappingURL=apiResponse.js.map