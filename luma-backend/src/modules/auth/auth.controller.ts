import type { Request, Response } from "express";
import { z } from "zod";

import { authService } from "./auth.service";
import { asyncHandler } from "../../utils/asyncHandler";
import { ApiError } from "../../utils/apiError";
import { toSuccess } from "../../utils/apiResponse";

const meResponseSchema = z.object({
  user: z.object({
    id: z.string(),
    email: z.string().nullable()
  })
});

export const authController = {
  me: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const payload = authService.getMe(user);
    // Validate response shape to keep API stable.
    const data = meResponseSchema.parse(payload);

    res.status(200).json(toSuccess(data));
  })
};

