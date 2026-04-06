import type { NextFunction, Request, Response, RequestHandler } from "express";
import { env } from "../config/env";
import { ApiError } from "../utils/apiError";

export const requireAdmin: RequestHandler = (req: Request, _res: Response, next: NextFunction) => {
  const email = req.user?.email;

  if (!email) {
    throw new ApiError(403, "FORBIDDEN", "Admin access required");
  }

  if (env.ADMIN_EMAILS.length === 0) {
    // No admins configured => deny by default to stay safe.
    throw new ApiError(403, "FORBIDDEN", "Admin access is not configured");
  }

  if (!env.ADMIN_EMAILS.includes(email)) {
    throw new ApiError(403, "FORBIDDEN", "Admin access required");
  }

  return next();
};

