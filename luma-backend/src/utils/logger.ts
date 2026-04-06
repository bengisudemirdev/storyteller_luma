import { env } from "../config/env";

type LogLevel = "debug" | "info" | "warn" | "error";

function toLevel(input: string): LogLevel {
  if (input === "debug") return "debug";
  if (input === "info") return "info";
  if (input === "warn") return "warn";
  if (input === "error") return "error";
  return "info";
}

const currentLevel = toLevel(env.LOG_LEVEL);

const priority: Record<LogLevel, number> = {
  debug: 10,
  info: 20,
  warn: 30,
  error: 40
};

function shouldLog(level: LogLevel): boolean {
  return priority[level] >= priority[currentLevel];
}

export const logger = {
  debug: (...args: Array<unknown>) => {
    if (!shouldLog("debug")) return;
    // eslint-disable-next-line no-console
    console.debug(...args);
  },
  info: (...args: Array<unknown>) => {
    if (!shouldLog("info")) return;
    // eslint-disable-next-line no-console
    console.info(...args);
  },
  warn: (...args: Array<unknown>) => {
    if (!shouldLog("warn")) return;
    // eslint-disable-next-line no-console
    console.warn(...args);
  },
  error: (...args: Array<unknown>) => {
    if (!shouldLog("error")) return;
    // eslint-disable-next-line no-console
    console.error(...args);
  }
};

