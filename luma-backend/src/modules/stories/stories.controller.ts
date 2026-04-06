import type { Request, Response } from "express";
import { z } from "zod";

import { asyncHandler } from "../../utils/asyncHandler";
import { ApiError } from "../../utils/apiError";
import { toSuccess } from "../../utils/apiResponse";
import { storiesService } from "./stories.service";

const listStoriesQuerySchema = z.object({
  limit: z
    .coerce.number()
    .int()
    .min(1)
    .max(100)
    .optional()
    .default(20)
});

/** Masal üretim isteği: yalnızca hikâyeye özel alanlar. Yaş/ilgi/korku çocuk kaydından okunur. */
const generateStorySchema = z.object({
  childId: z.string().min(1),
  theme: z.string().min(1).max(120),
  language: z.string().min(2).max(32).optional().nullable(),
  extraContext: z.string().max(500).optional().nullable(),
  selectedInterests: z.array(z.string().min(1).max(80)).max(25).optional(),
  storyGoal: z.string().max(300).optional().nullable()
});

export const storiesController = {
  list: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const query = listStoriesQuerySchema.parse(req.query);
    const stories = await storiesService.listStories(user.id, query.limit);

    res.status(200).json(toSuccess({ stories }));
  }),

  getById: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const storyId = z.string().min(1).parse(req.params.id);
    const story = await storiesService.getStoryById(user.id, storyId);

    res.status(200).json(toSuccess({ story }));
  }),

  deleteById: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const storyId = z.string().min(1).parse(req.params.id);
    const story = await storiesService.deleteStoryById(user.id, storyId);

    res.status(200).json(toSuccess({ story }));
  }),

  generate: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const payload = generateStorySchema.parse(req.body);
    const story = await storiesService.generateStory({
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

    res.status(200).json(toSuccess({ story }));
  })
};
