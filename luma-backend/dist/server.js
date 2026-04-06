"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const env_1 = require("./config/env");
const app_1 = require("./app");
const logger_1 = require("./utils/logger");
async function main() {
    const server = app_1.app.listen(env_1.env.PORT, env_1.env.HOST, () => {
        logger_1.logger.info(`Server listening on http://${env_1.env.HOST}:${env_1.env.PORT}`);
    });
    // Handle graceful shutdown.
    const shutdown = (signal) => {
        logger_1.logger.info(`Received ${signal}, shutting down...`);
        server.close(() => {
            logger_1.logger.info("HTTP server closed.");
            process.exit(0);
        });
    };
    process.on("SIGINT", shutdown);
    process.on("SIGTERM", shutdown);
}
void main();
//# sourceMappingURL=server.js.map