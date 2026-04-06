"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.subscriptionController = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const apiError_1 = require("../../utils/apiError");
const apiResponse_1 = require("../../utils/apiResponse");
const subscription_service_1 = require("./subscription.service");
exports.subscriptionController = {
    status: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const status = await subscription_service_1.subscriptionService.getSubscriptionStatus(user.id);
        res.status(200).json((0, apiResponse_1.toSuccess)({ subscription: status }));
    })
};
//# sourceMappingURL=subscription.controller.js.map