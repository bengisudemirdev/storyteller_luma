import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { subscriptionController } from "./subscription.controller";

export const subscriptionRoutes = Router();

/**
 * @openapi
 * tags:
 *   - name: Subscription
 * /v1/subscription/status:
 *   get:
 *     summary: Get subscription status
 *     tags: [Subscription]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: OK
 */
subscriptionRoutes.get("/status", requireAuth, subscriptionController.status);

