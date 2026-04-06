import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { authController } from "./auth.controller";

export const authRoutes = Router();

/**
 * @openapi
 * tags:
 *   - name: Auth
 * /v1/auth/me:
 *   post:
 *     summary: Get current user
 *     tags: [Auth]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: OK
 */
authRoutes.post("/me", requireAuth, authController.me);

