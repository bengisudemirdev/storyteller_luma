"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.childrenRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const children_controller_1 = require("./children.controller");
exports.childrenRoutes = (0, express_1.Router)();
/**
 * @openapi
 * tags:
 *   - name: Children
 */
exports.childrenRoutes.post("/", auth_middleware_1.requireAuth, children_controller_1.childrenController.createChild);
exports.childrenRoutes.get("/", auth_middleware_1.requireAuth, children_controller_1.childrenController.listChildren);
exports.childrenRoutes.patch("/:id", auth_middleware_1.requireAuth, children_controller_1.childrenController.updateChild);
exports.childrenRoutes.delete("/:id", auth_middleware_1.requireAuth, children_controller_1.childrenController.deleteChild);
//# sourceMappingURL=children.routes.js.map