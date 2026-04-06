"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.subscriptionRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const subscription_controller_1 = require("./subscription.controller");
exports.subscriptionRoutes = (0, express_1.Router)();
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
exports.subscriptionRoutes.get("/status", auth_middleware_1.requireAuth, subscription_controller_1.subscriptionController.status);
//# sourceMappingURL=subscription.routes.js.map