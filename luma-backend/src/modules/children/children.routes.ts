import { Router } from "express";
import { requireAuth } from "../../middlewares/auth.middleware";
import { childrenController } from "./children.controller";

export const childrenRoutes = Router();

/**
 * @openapi
 * tags:
 *   - name: Children
 */
childrenRoutes.post("/", requireAuth, childrenController.createChild);
childrenRoutes.get("/", requireAuth, childrenController.listChildren);
childrenRoutes.patch("/:id", requireAuth, childrenController.updateChild);
childrenRoutes.delete("/:id", requireAuth, childrenController.deleteChild);

