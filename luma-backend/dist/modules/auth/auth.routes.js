"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const auth_controller_1 = require("./auth.controller");
exports.authRoutes = (0, express_1.Router)();
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
exports.authRoutes.post("/me", auth_middleware_1.requireAuth, auth_controller_1.authController.me);
//# sourceMappingURL=auth.routes.js.map