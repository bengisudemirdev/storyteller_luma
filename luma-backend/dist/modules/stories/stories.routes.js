"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.storiesRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const stories_controller_1 = require("./stories.controller");
exports.storiesRoutes = (0, express_1.Router)();
/**
 * @openapi
 * tags:
 *   - name: Stories
 * /v1/stories/generate:
 *   post:
 *     summary: Generate story
 *     tags: [Stories]
 *     security:
 *       - BearerAuth: []
 */
exports.storiesRoutes.post("/generate", auth_middleware_1.requireAuth, stories_controller_1.storiesController.generate);
exports.storiesRoutes.get("/", auth_middleware_1.requireAuth, stories_controller_1.storiesController.list);
exports.storiesRoutes.get("/:id", auth_middleware_1.requireAuth, stories_controller_1.storiesController.getById);
exports.storiesRoutes.delete("/:id", auth_middleware_1.requireAuth, stories_controller_1.storiesController.deleteById);
//# sourceMappingURL=stories.routes.js.map