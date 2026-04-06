import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";
import { ApiError } from "../utils/apiError";
import { toError } from "../utils/apiResponse";
import { logger } from "../utils/logger";
import { isPostgrestLikeError } from "../utils/postgrestError";

export function errorMiddleware(err: unknown, req: Request, res: Response, _next: NextFunction): void {
  const requestId = req.requestId ?? (req.headers["x-request-id"] as string | undefined) ?? undefined;

  if (err instanceof ApiError) {
    logger.error("API error:", {
      requestId,
      code: err.code,
      statusCode: err.statusCode,
      message: err.message
    });

    res.status(err.statusCode).json(
      toError(err.code, err.message, {
        ...(err.details ? { details: err.details } : null),
        requestId
      })
    );
    return;
  }

  if (err instanceof ZodError) {
    logger.warn("Validation error:", {
      requestId,
      issues: err.issues
    });
    res.status(400).json(
      toError("VALIDATION_ERROR", "Invalid request body", {
        issues: err.issues,
        requestId
      })
    );
    return;
  }

  const isProd = process.env.NODE_ENV === "production";
  const baseLog: Record<string, unknown> = {
    requestId,
    message: err instanceof Error ? err.message : "Unknown error",
    stack: err instanceof Error ? (isProd ? undefined : err.stack) : undefined
  };
  if (isPostgrestLikeError(err)) {
    baseLog.postgrestCode = err.code;
    if (err.details) baseLog.postgrestDetails = err.details;
    if (err.hint) baseLog.postgrestHint = err.hint;
  }
  logger.error("Unhandled error:", baseLog);

  res.status(500).json(
    toError("INTERNAL_SERVER_ERROR", "An unexpected error occurred", {
      requestId
    })
  );
}

