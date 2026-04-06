import type { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { ApiError } from "../../utils/apiError";
import { toSuccess } from "../../utils/apiResponse";
import { subscriptionService } from "./subscription.service";

export const subscriptionController = {
  status: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const status = await subscriptionService.getSubscriptionStatus(user.id);

    res.status(200).json(toSuccess({ subscription: status }));
  })
};

