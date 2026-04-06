import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { usageController } from "./usage.controller";

export const usageRoutes = Router();

/**
 * @openapi
 * tags:
 *   - name: Usage
 * /v1/usage:
 *   get:
 *     summary: Get daily usage
 *     tags: [Usage]
 *     security:
 *       - BearerAuth: []
 */
usageRoutes.get("/", requireAuth, usageController.daily);

