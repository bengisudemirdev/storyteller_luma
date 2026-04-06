import type { Request, Response } from "express";
import { z } from "zod";

import { asyncHandler } from "../../utils/asyncHandler";
import { ApiError } from "../../utils/apiError";
import { toSuccess } from "../../utils/apiResponse";
import { childrenService } from "./children.service";
import { logStructured } from "../../utils/structuredLog";

const tagArray = z.array(z.string().trim().min(1).max(80)).max(25);

const createChildSchema = z.object({
  name: z.string().min(1).max(50),
  age: z.number().int().min(0).max(15).optional().nullable(),
  profile: z.string().max(500).optional().nullable(),
  avatar_emoji: z.string().min(1).max(16).optional(),
  interests: tagArray.optional(),
  fears: tagArray.optional()
});

const updateChildSchema = z.object({
  name: z.string().min(1).max(50).optional(),
  age: z.number().int().min(0).max(15).optional().nullable(),
  profile: z.string().max(500).optional().nullable(),
  avatar_emoji: z.string().min(1).max(16).optional().nullable(),
  interests: tagArray.optional().nullable(),
  fears: tagArray.optional().nullable()
});

export const childrenController = {
  createChild: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    logStructured("info", "children.create.started", {
      requestId: req.requestId,
      route: "POST /v1/children",
      userId: user.id,
      action: "children.create",
      result: "started"
    });

    const payload = createChildSchema.parse(req.body);
    const child = await childrenService.createChild({
      userId: user.id,
      name: payload.name,
      age: payload.age ?? null,
      profile: payload.profile ?? null,
      avatar_emoji: payload.avatar_emoji ?? null,
      interests: payload.interests ?? null,
      fears: payload.fears ?? null
    });

    logStructured("info", "children.create.completed", {
      requestId: req.requestId,
      route: "POST /v1/children",
      userId: user.id,
      childId: child.id,
      action: "children.create",
      result: "ok"
    });

    res.status(200).json(toSuccess({ child }));
  }),

  listChildren: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    logStructured("info", "children.fetch.started", {
      requestId: req.requestId,
      route: "GET /v1/children",
      userId: user.id,
      action: "children.list",
      result: "started"
    });

    const children = await childrenService.listChildren(user.id);

    logStructured("info", "children.fetch.completed", {
      requestId: req.requestId,
      route: "GET /v1/children",
      userId: user.id,
      action: "children.list",
      count: children.length,
      result: "ok"
    });

    res.status(200).json(toSuccess({ children }));
  }),

  updateChild: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const childId = z.string().min(1).parse(req.params.id);

    logStructured("info", "children.update.started", {
      requestId: req.requestId,
      route: "PATCH /v1/children/:id",
      userId: user.id,
      childId,
      action: "children.update",
      result: "started"
    });

    const payload = updateChildSchema.parse(req.body);
    const child = await childrenService.updateChildForUser(user.id, childId, payload);

    logStructured("info", "children.update.completed", {
      requestId: req.requestId,
      route: "PATCH /v1/children/:id",
      userId: user.id,
      childId: child.id,
      action: "children.update",
      result: "ok"
    });

    res.status(200).json(toSuccess({ child }));
  }),

  deleteChild: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const childId = z.string().min(1).parse(req.params.id);
    const child = await childrenService.deleteChildForUser(user.id, childId);

    res.status(200).json(toSuccess({ child }));
  })
};
