"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logger = void 0;
const env_1 = require("../config/env");
function toLevel(input) {
    if (input === "debug")
        return "debug";
    if (input === "info")
        return "info";
    if (input === "warn")
        return "warn";
    if (input === "error")
        return "error";
    return "info";
}
const currentLevel = toLevel(env_1.env.LOG_LEVEL);
const priority = {
    debug: 10,
    info: 20,
    warn: 30,
    error: 40
};
function shouldLog(level) {
    return priority[level] >= priority[currentLevel];
}
exports.logger = {
    debug: (...args) => {
        if (!shouldLog("debug"))
            return;
        // eslint-disable-next-line no-console
        console.debug(...args);
    },
    info: (...args) => {
        if (!shouldLog("info"))
            return;
        // eslint-disable-next-line no-console
        console.info(...args);
    },
    warn: (...args) => {
        if (!shouldLog("warn"))
            return;
        // eslint-disable-next-line no-console
        console.warn(...args);
    },
    error: (...args) => {
        if (!shouldLog("error"))
            return;
        // eslint-disable-next-line no-console
        console.error(...args);
    }
};
//# sourceMappingURL=logger.js.map