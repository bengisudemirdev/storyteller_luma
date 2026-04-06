"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.childrenController = void 0;
const zod_1 = require("zod");
const asyncHandler_1 = require("../../utils/asyncHandler");
const apiError_1 = require("../../utils/apiError");
const apiResponse_1 = require("../../utils/apiResponse");
const children_service_1 = require("./children.service");
const structuredLog_1 = require("../../utils/structuredLog");
const tagArray = zod_1.z.array(zod_1.z.string().trim().min(1).max(80)).max(25);
const createChildSchema = zod_1.z.object({
    name: zod_1.z.string().min(1).max(50),
    age: zod_1.z.number().int().min(0).max(15).optional().nullable(),
    profile: zod_1.z.string().max(500).optional().nullable(),
    avatar_emoji: zod_1.z.string().min(1).max(16).optional(),
    interests: tagArray.optional(),
    fears: tagArray.optional()
});
const updateChildSchema = zod_1.z.object({
    name: zod_1.z.string().min(1).max(50).optional(),
    age: zod_1.z.number().int().min(0).max(15).optional().nullable(),
    profile: zod_1.z.string().max(500).optional().nullable(),
    avatar_emoji: zod_1.z.string().min(1).max(16).optional().nullable(),
    interests: tagArray.optional().nullable(),
    fears: tagArray.optional().nullable()
});
exports.childrenController = {
    createChild: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        (0, structuredLog_1.logStructured)("info", "children.create.started", {
            requestId: req.requestId,
            route: "POST /v1/children",
            userId: user.id,
            action: "children.create",
            result: "started"
        });
        const payload = createChildSchema.parse(req.body);
        const child = await children_service_1.childrenService.createChild({
            userId: user.id,
            name: payload.name,
            age: payload.age ?? null,
            profile: payload.profile ?? null,
            avatar_emoji: payload.avatar_emoji ?? null,
            interests: payload.interests ?? null,
            fears: payload.fears ?? null
        });
        (0, structuredLog_1.logStructured)("info", "children.create.completed", {
            requestId: req.requestId,
            route: "POST /v1/children",
            userId: user.id,
            childId: child.id,
            action: "children.create",
            result: "ok"
        });
        res.status(200).json((0, apiResponse_1.toSuccess)({ child }));
    }),
    listChildren: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        (0, structuredLog_1.logStructured)("info", "children.fetch.started", {
            requestId: req.requestId,
            route: "GET /v1/children",
            userId: user.id,
            action: "children.list",
            result: "started"
        });
        const children = await children_service_1.childrenService.listChildren(user.id);
        (0, structuredLog_1.logStructured)("info", "children.fetch.completed", {
            requestId: req.requestId,
            route: "GET /v1/children",
            userId: user.id,
            action: "children.list",
            count: children.length,
            result: "ok"
        });
        res.status(200).json((0, apiResponse_1.toSuccess)({ children }));
    }),
    updateChild: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const childId = zod_1.z.string().min(1).parse(req.params.id);
        (0, structuredLog_1.logStructured)("info", "children.update.started", {
            requestId: req.requestId,
            route: "PATCH /v1/children/:id",
            userId: user.id,
            childId,
            action: "children.update",
            result: "started"
        });
        const payload = updateChildSchema.parse(req.body);
        const child = await children_service_1.childrenService.updateChildForUser(user.id, childId, payload);
        (0, structuredLog_1.logStructured)("info", "children.update.completed", {
            requestId: req.requestId,
            route: "PATCH /v1/children/:id",
            userId: user.id,
            childId: child.id,
            action: "children.update",
            result: "ok"
        });
        res.status(200).json((0, apiResponse_1.toSuccess)({ child }));
    }),
    deleteChild: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const childId = zod_1.z.string().min(1).parse(req.params.id);
        const child = await children_service_1.childrenService.deleteChildForUser(user.id, childId);
        res.status(200).json((0, apiResponse_1.toSuccess)({ child }));
    })
};
//# sourceMappingURL=children.controller.js.map