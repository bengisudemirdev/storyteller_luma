"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.storiesController = void 0;
const zod_1 = require("zod");
const asyncHandler_1 = require("../../utils/asyncHandler");
const apiError_1 = require("../../utils/apiError");
const apiResponse_1 = require("../../utils/apiResponse");
const stories_service_1 = require("./stories.service");
const listStoriesQuerySchema = zod_1.z.object({
    limit: zod_1.z
        .coerce.number()
        .int()
        .min(1)
        .max(100)
        .optional()
        .default(20)
});
/** Masal üretim isteği: yalnızca hikâyeye özel alanlar. Yaş/ilgi/korku çocuk kaydından okunur. */
const generateStorySchema = zod_1.z.object({
    childId: zod_1.z.string().min(1),
    theme: zod_1.z.string().min(1).max(120),
    language: zod_1.z.string().min(2).max(32).optional().nullable(),
    extraContext: zod_1.z.string().max(500).optional().nullable(),
    selectedInterests: zod_1.z.array(zod_1.z.string().min(1).max(80)).max(25).optional(),
    storyGoal: zod_1.z.string().max(300).optional().nullable()
});
exports.storiesController = {
    list: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const query = listStoriesQuerySchema.parse(req.query);
        const stories = await stories_service_1.storiesService.listStories(user.id, query.limit);
        res.status(200).json((0, apiResponse_1.toSuccess)({ stories }));
    }),
    getById: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const storyId = zod_1.z.string().min(1).parse(req.params.id);
        const story = await stories_service_1.storiesService.getStoryById(user.id, storyId);
        res.status(200).json((0, apiResponse_1.toSuccess)({ story }));
    }),
    deleteById: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const storyId = zod_1.z.string().min(1).parse(req.params.id);
        const story = await stories_service_1.storiesService.deleteStoryById(user.id, storyId);
        res.status(200).json((0, apiResponse_1.toSuccess)({ story }));
    }),
    generate: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const payload = generateStorySchema.parse(req.body);
        const story = await stories_service_1.storiesService.generateStory({
            userId: user.id,
            childId: payload.childId,
            theme: payload.theme,
            language: payload.language ?? null,
            extraContext: payload.extraContext ?? null,
            selectedInterests: payload.selectedInterests ?? null,
            storyGoal: payload.storyGoal ?? null,
            requestId: req.requestId,
            route: "POST /v1/stories/generate"
        });
        res.status(200).json((0, apiResponse_1.toSuccess)({ story }));
    })
};
//# sourceMappingURL=stories.controller.js.map