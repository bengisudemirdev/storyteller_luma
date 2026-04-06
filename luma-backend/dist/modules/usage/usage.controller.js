"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.usageController = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const apiError_1 = require("../../utils/apiError");
const apiResponse_1 = require("../../utils/apiResponse");
const subscription_service_1 = require("../subscription/subscription.service");
const usage_service_1 = require("./usage.service");
exports.usageController = {
    daily: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const subscription = await subscription_service_1.subscriptionService.getSubscriptionStatus(user.id);
        const usage = await usage_service_1.usageService.getDailyUsage(user.id, subscription.plan);
        res.status(200).json((0, apiResponse_1.toSuccess)({ usage }));
    })
};
//# sourceMappingURL=usage.controller.js.map