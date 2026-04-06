import { logger } from "./logger";

export type StructuredFields = Record<string, string | number | boolean | null | undefined>;

/**
 * Tek satır JSON — log aggregator / grep için.
 */
export function logStructured(
  level: "debug" | "info" | "warn" | "error",
  event: string,
  fields: StructuredFields
): void {
  const line = JSON.stringify({
    event,
    ts: new Date().toISOString(),
    ...fields
  });
  logger[level](line);
}
