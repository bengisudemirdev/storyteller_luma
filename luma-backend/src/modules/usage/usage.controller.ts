import type { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { ApiError } from "../../utils/apiError";
import { toSuccess } from "../../utils/apiResponse";
import { subscriptionService } from "../subscription/subscription.service";
import { usageService } from "./usage.service";

export const usageController = {
  daily: asyncHandler(async (req: Request, res: Response) => {
    const user = req.user;
    if (!user) throw ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");

    const subscription = await subscriptionService.getSubscriptionStatus(user.id);
    const usage = await usageService.getDailyUsage(user.id, subscription.plan);

    res.status(200).json(toSuccess({ usage }));
  })
};

