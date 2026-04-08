import type { Request, Response, NextFunction, RequestHandler } from "express";
import { supabaseAdmin } from "../config/supabase";
import { ApiError } from "../utils/apiError";
import { asyncHandler } from "../utils/asyncHandler";
import { authService } from "../modules/auth/auth.service";

export type AuthUser = { id: string; email?: string | null };

declare global {
  namespace Express {
    // Augment Express request object with authenticated user.
    interface Request {
      user?: AuthUser;
    }
  }
}

function extractBearerToken(req: Request): string | null {
  const header = req.headers.authorization;
  if (!header || typeof header !== "string") return null;
  const trimmed = header.trim();
  const m = /^Bearer\s+(.+)$/i.exec(trimmed);
  if (!m) return null;
  // Swagger UI already sends "Bearer <value>"; users often paste "Bearer eyJ..." into the Authorize box → double prefix.
  let token = m[1].trim().replace(/^Bearer\s+/i, "").trim();
  // Kopyala-yapıştırda gelen satır sonu / boşluklar JWT'yi bozar.
  token = token.replace(/\s/g, "");
  return token.length > 0 ? token : null;
}

export const requireAuth: RequestHandler = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const token = extractBearerToken(req);
  if (!token) {
    throw ApiError.unauthorized("MISSING_BEARER_TOKEN", "Missing Bearer token");
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data?.user) {
    if (process.env.NODE_ENV !== "production") {
      // Token asla loglanmaz; Supabase hata mesajı projeyi hizalamak için yeterli ipucu verir.
      console.warn("[requireAuth] supabase.auth.getUser failed:", error?.message ?? "no user");
    }
    throw ApiError.unauthorized("INVALID_TOKEN", "Invalid or expired token");
  }

  const user: AuthUser = {
    id: data.user.id,
    email: data.user.email
  };

  // Ensure app profile row exists (parents table) for future queries.
  await authService.ensureUserRow(user);

  req.user = user;
  return next();
});

