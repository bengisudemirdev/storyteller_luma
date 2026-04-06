import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { storiesController } from "./stories.controller";

export const storiesRoutes = Router();

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
storiesRoutes.post("/generate", requireAuth, storiesController.generate);
storiesRoutes.get("/", requireAuth, storiesController.list);
storiesRoutes.get("/:id", requireAuth, storiesController.getById);
storiesRoutes.delete("/:id", requireAuth, storiesController.deleteById);

