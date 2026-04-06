import { randomUUID } from "crypto";
import type { RequestHandler } from "express";

/**
 * Her isteğe requestId atar (X-Request-Id header veya yeni UUID) ve yanıta yazar.
 */
export const requestContextMiddleware: RequestHandler = (req, res, next) => {
  const fromHeader = req.headers["x-request-id"];
  const id = typeof fromHeader === "string" && fromHeader.trim().length > 0 ? fromHeader.trim() : randomUUID();
  req.requestId = id;
  res.setHeader("x-request-id", id);
  next();
};
