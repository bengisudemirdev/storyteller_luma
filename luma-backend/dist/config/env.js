"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const zod_1 = require("zod");
dotenv_1.default.config();
const envSchema = zod_1.z.object({
    PORT: zod_1.z.coerce.number().int().min(1).max(65535).default(3001),
    /** Dinleme adresi: Docker / bulut için genelde 0.0.0.0 */
    HOST: zod_1.z.string().min(1).default("0.0.0.0"),
    LOG_LEVEL: zod_1.z.string().default("info"),
    JSON_BODY_LIMIT: zod_1.z.string().default("1mb"),
    LOG_FORMAT: zod_1.z.string().default("combined"),
    API_BASE_URL: zod_1.z.string().url().optional().default("http://localhost:3001"),
    // CORS
    CORS_ORIGINS: zod_1.z.string().optional().default(""),
    // Rate limiting
    RATE_LIMIT_WINDOW_MS: zod_1.z.coerce.number().int().positive().default(900000),
    /** Aynı IP için pencere başına max istek (uygulama + Swagger ortak sayaç). */
    RATE_LIMIT_MAX: zod_1.z.coerce.number().int().positive().default(300),
    STORIES_GENERATE_RATE_LIMIT_WINDOW_MS: zod_1.z.coerce.number().int().positive().default(900000),
    STORIES_GENERATE_RATE_LIMIT_MAX: zod_1.z.coerce.number().int().positive().default(30),
    /** `true` / `1` ise genel ve masal-üretim rate limit devre dışı (yalnızca güvenilir ortamda). */
    RATE_LIMIT_DISABLED: zod_1.z
        .preprocess((v) => {
        if (v === undefined || v === null || v === "")
            return false;
        const s = String(v).trim().toLowerCase();
        return s === "true" || s === "1" || s === "yes";
    }, zod_1.z.boolean())
        .default(false),
    // Usage limits (per day)
    DAILY_FREE_STORY_LIMIT: zod_1.z.coerce.number().int().nonnegative().default(5),
    DAILY_PREMIUM_STORY_LIMIT: zod_1.z.coerce.number().int().nonnegative().default(50),
    // Supabase
    SUPABASE_URL: zod_1.z.string().url(),
    SUPABASE_SERVICE_ROLE_KEY: zod_1.z.string().min(20),
    // OpenAI
    OPENAI_API_KEY: zod_1.z.string().min(10),
    OPENAI_MODEL: zod_1.z.string().default("gpt-4o-mini"),
    OPENAI_TEMPERATURE: zod_1.z.coerce.number().min(0).max(2).default(0.7),
    /** `openai.images.generate` — `gpt-image-1` (default) or `dall-e-3` */
    OPENAI_IMAGE_MODEL: zod_1.z.string().min(1).default("gpt-image-1"),
    // Swagger / docs
    SWAGGER_ENABLED: zod_1.z.coerce.boolean().default(process.env.NODE_ENV === "production" ? false : true),
    SWAGGER_BASIC_AUTH_USERNAME: zod_1.z.string().min(1).default("docs_user"),
    SWAGGER_BASIC_AUTH_PASSWORD: zod_1.z.string().min(1).default("docs_password"),
    // Admin authorization
    ADMIN_EMAILS: zod_1.z.string().optional().default(""),
    // Supabase Storage
    SUPABASE_STORAGE_BUCKET_STORIES: zod_1.z.string().min(1).default("luma-stories-assets")
});
const parsed = envSchema.parse(process.env);
function splitOrigins(value) {
    return value
        .split(",")
        .map((v) => v.trim())
        .filter(Boolean);
}
exports.env = {
    ...parsed,
    get TRUST_PROXY() {
        const v = process.env.TRUST_PROXY;
        if (v === "1" || v === "true")
            return true;
        if (v === "0" || v === "false")
            return false;
        return process.env.NODE_ENV === "production";
    },
    get CORS_ORIGINS() {
        return splitOrigins(parsed.CORS_ORIGINS);
    },
    get ADMIN_EMAILS() {
        return splitOrigins(parsed.ADMIN_EMAILS ?? "");
    }
};
//# sourceMappingURL=env.js.map