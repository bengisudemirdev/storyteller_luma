import { env } from "./config/env";
import { app } from "./app";
import { logger } from "./utils/logger";

async function main(): Promise<void> {
  const server = app.listen(env.PORT, env.HOST, () => {
    logger.info(`Server listening on http://${env.HOST}:${env.PORT}`);
  });

  // Handle graceful shutdown.
  const shutdown = (signal: NodeJS.Signals) => {
    logger.info(`Received ${signal}, shutting down...`);
    server.close(() => {
      logger.info("HTTP server closed.");
      process.exit(0);
    });
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

void main();

