"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.usageRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const usage_controller_1 = require("./usage.controller");
exports.usageRoutes = (0, express_1.Router)();
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
exports.usageRoutes.get("/", auth_middleware_1.requireAuth, usage_controller_1.usageController.daily);
//# sourceMappingURL=usage.routes.js.map