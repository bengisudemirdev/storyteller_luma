import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import { env } from "./config/env";
import { v1RateLimiter, storiesGenerateRateLimiter } from "./middlewares/rateLimit.middleware";
import { errorMiddleware } from "./middlewares/error.middleware";

import { authRoutes } from "./modules/auth/auth.routes";
import { childrenRoutes } from "./modules/children/children.routes";
import { storiesRoutes } from "./modules/stories/stories.routes";
import { usageRoutes } from "./modules/usage/usage.routes";
import { subscriptionRoutes } from "./modules/subscription/subscription.routes";

import { ApiError } from "./utils/apiError";
import { swaggerUi, swaggerSpec, swaggerBasicAuthMiddleware } from "./config/swagger";
import { requestContextMiddleware } from "./middlewares/requestContext.middleware";

export const app = express();

app.disable("x-powered-by");

if (env.TRUST_PROXY) {
  app.set("trust proxy", 1);
}

app.get("/", (_req, res) => {
  res.status(200).json({
    success: true,
    data: {
      service: "luma-backend",
      health: "/v1/health",
      docs: env.SWAGGER_ENABLED ? "/docs" : null
    }
  });
});

app.use(
  helmet({
    // API server; keep security headers without enforcing browser-specific CSP.
    contentSecurityPolicy: false
  })
);

const allowedOrigins = env.CORS_ORIGINS;
app.use(
  cors({
    origin: (origin, callback) => {
      // Mobile apps might not send Origin; allow those.
      if (!origin) return callback(null, true);
      if (allowedOrigins.length === 0) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      return callback(new ApiError(403, "CORS_FORBIDDEN", "Origin not allowed"));
    },
    credentials: false
  })
);

app.use(requestContextMiddleware);
app.use(express.json({ limit: env.JSON_BODY_LIMIT }));
app.use(morgan(env.LOG_FORMAT));

// Health endpoint (not part of your required list, safe to keep).
app.get("/v1/health", (_req, res) => {
  res.status(200).json({ success: true, data: { ok: true } });
});

// Rate limit for everything under /v1.
app.use("/v1", v1RateLimiter);
// Extra stricter limiter for story generation endpoint.
app.use("/v1/stories/generate", storiesGenerateRateLimiter);

// Routes
app.use("/v1/auth", authRoutes);
app.use("/v1/children", childrenRoutes);
app.use("/v1/stories", storiesRoutes);
app.use("/v1/usage", usageRoutes);
app.use("/v1/subscription", subscriptionRoutes);

// OpenAPI docs (Basic-auth protected).
if (env.SWAGGER_ENABLED) {
  app.use("/docs", swaggerBasicAuthMiddleware, swaggerUi.serve, swaggerUi.setup(swaggerSpec));
}

// 404 handler
app.use((req, _res, next) => {
  next(new ApiError(404, "NOT_FOUND", `Route not found: ${req.method} ${req.path}`));
});

app.use(errorMiddleware);

