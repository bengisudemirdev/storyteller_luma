import type { Request } from "express";

declare global {
  namespace Express {
    interface Request {
      /** Correlation id (header veya otomatik) */
      requestId: string;
    }
  }
}

export {};
