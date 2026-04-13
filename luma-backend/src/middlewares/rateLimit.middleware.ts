import rateLimit from "express-rate-limit";
import { env } from "../config/env";
import { toError } from "../utils/apiResponse";
import type { Request, Response } from "express";

function isV1HealthCheck(req: Request): boolean {
  if (req.method !== "GET") return false;
  const path = (req.originalUrl ?? "").split("?")[0] ?? "";
  return path === "/v1/health";
}

function jsonRateLimitHandler(req: Request, res: Response): void {
  res.status(429).json(
    toError("RATE_LIMITED", "Rate limit exceeded", {
      method: req.method,
      path: req.originalUrl,
      ip: req.ip
    })
  );
}

export const v1RateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  limit: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => env.RATE_LIMIT_DISABLED || isV1HealthCheck(req),
  handler: (req, res) => {
    jsonRateLimitHandler(req, res);
  },
  keyGenerator: (req) => {
    // Authenticated users share a limiter by IP to keep implementation simple.
    // If you want per-user rate limiting, you can key off the Bearer token claim after validation.
    return req.ip ?? "unknown";
  }
});

export const storiesGenerateRateLimiter = rateLimit({
  windowMs: env.STORIES_GENERATE_RATE_LIMIT_WINDOW_MS,
  limit: env.STORIES_GENERATE_RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => env.RATE_LIMIT_DISABLED,
  handler: (req, res) => {
    jsonRateLimitHandler(req, res);
  },
  keyGenerator: (req) => req.ip ?? "unknown"
});

