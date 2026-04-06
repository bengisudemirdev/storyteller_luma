"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.safeUnknownErrorFields = safeUnknownErrorFields;
/**
 * Bilinmeyen hataları log / güvenli response details için düzleştirir.
 * Token, key veya tam SQL içeriği ekleme.
 */
function safeUnknownErrorFields(err, includeStack) {
    const out = {};
    if (err instanceof Error) {
        out.errorName = err.name;
        out.errorMessage = err.message.slice(0, 2000);
        if (includeStack && err.stack) {
            out.stack = err.stack.slice(0, 8000);
        }
        return out;
    }
    if (err && typeof err === "object") {
        const o = err;
        if (typeof o.message === "string")
            out.errorMessage = o.message.slice(0, 2000);
        if (typeof o.code === "string" || typeof o.code === "number")
            out.vendorCode = String(o.code);
        if (typeof o.details === "string")
            out.vendorDetails = o.details.slice(0, 500);
        if (typeof o.hint === "string")
            out.vendorHint = o.hint.slice(0, 300);
        if (Object.keys(out).length === 0) {
            try {
                out.errorMessage = JSON.stringify(o).slice(0, 1500);
            }
            catch {
                out.errorMessage = String(err).slice(0, 500);
            }
        }
        return out;
    }
    out.errorMessage = String(err).slice(0, 500);
    return out;
}
//# sourceMappingURL=safeErrorDetails.js.map