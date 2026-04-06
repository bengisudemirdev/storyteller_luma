"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authController = void 0;
const zod_1 = require("zod");
const auth_service_1 = require("./auth.service");
const asyncHandler_1 = require("../../utils/asyncHandler");
const apiError_1 = require("../../utils/apiError");
const apiResponse_1 = require("../../utils/apiResponse");
const meResponseSchema = zod_1.z.object({
    user: zod_1.z.object({
        id: zod_1.z.string(),
        email: zod_1.z.string().nullable()
    })
});
exports.authController = {
    me: (0, asyncHandler_1.asyncHandler)(async (req, res) => {
        const user = req.user;
        if (!user)
            throw apiError_1.ApiError.unauthorized("UNAUTHORIZED", "User not authenticated");
        const payload = auth_service_1.authService.getMe(user);
        // Validate response shape to keep API stable.
        const data = meResponseSchema.parse(payload);
        res.status(200).json((0, apiResponse_1.toSuccess)(data));
    })
};
//# sourceMappingURL=auth.controller.js.map