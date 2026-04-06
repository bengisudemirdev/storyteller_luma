"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logStructured = logStructured;
const logger_1 = require("./logger");
/**
 * Tek satır JSON — log aggregator / grep için.
 */
function logStructured(level, event, fields) {
    const line = JSON.stringify({
        event,
        ts: new Date().toISOString(),
        ...fields
    });
    logger_1.logger[level](line);
}
//# sourceMappingURL=structuredLog.js.map