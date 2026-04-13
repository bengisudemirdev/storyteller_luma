import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3001),
  /** Dinleme adresi: Docker / bulut için genelde 0.0.0.0 */
  HOST: z.string().min(1).default("0.0.0.0"),
  LOG_LEVEL: z.string().default("info"),

  JSON_BODY_LIMIT: z.string().default("1mb"),
  LOG_FORMAT: z.string().default("combined"),

  API_BASE_URL: z.string().url().optional().default("http://localhost:3001"),

  // CORS
  CORS_ORIGINS: z.string().optional().default(""),

  // Rate limiting
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(900000),
  /** Aynı IP için pencere başına max istek (uygulama + Swagger ortak sayaç). */
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(300),
  STORIES_GENERATE_RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(900000),
  STORIES_GENERATE_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(30),
  /** `true` / `1` ise genel ve masal-üretim rate limit devre dışı (yalnızca güvenilir ortamda). */
  RATE_LIMIT_DISABLED: z
    .preprocess((v) => {
      if (v === undefined || v === null || v === "") return false;
      const s = String(v).trim().toLowerCase();
      return s === "true" || s === "1" || s === "yes";
    }, z.boolean())
    .default(false),

  // Usage limits (per day)
  DAILY_FREE_STORY_LIMIT: z.coerce.number().int().nonnegative().default(5),
  DAILY_PREMIUM_STORY_LIMIT: z.coerce.number().int().nonnegative().default(50),

  // Supabase
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),

  // OpenAI
  OPENAI_API_KEY: z.string().min(10),
  OPENAI_MODEL: z.string().default("gpt-4o-mini"),
  OPENAI_TEMPERATURE: z.coerce.number().min(0).max(2).default(0.7),
  /** `openai.images.generate` — `gpt-image-1` (default) or `dall-e-3` */
  OPENAI_IMAGE_MODEL: z.string().min(1).default("gpt-image-1"),

  // Swagger / docs
  SWAGGER_ENABLED: z.coerce.boolean().default(process.env.NODE_ENV === "production" ? false : true),
  SWAGGER_BASIC_AUTH_USERNAME: z.string().min(1).default("docs_user"),
  SWAGGER_BASIC_AUTH_PASSWORD: z.string().min(1).default("docs_password"),

  // Admin authorization
  ADMIN_EMAILS: z.string().optional().default(""),

  // Supabase Storage
  SUPABASE_STORAGE_BUCKET_STORIES: z.string().min(1).default("luma-stories-assets")
});

const parsed = envSchema.parse(process.env);

function splitOrigins(value: string): string[] {
  return value
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);
}

export const env = {
  ...parsed,
  get TRUST_PROXY(): boolean {
    const v = process.env.TRUST_PROXY;
    if (v === "1" || v === "true") return true;
    if (v === "0" || v === "false") return false;
    return process.env.NODE_ENV === "production";
  },
  get CORS_ORIGINS(): string[] {
    return splitOrigins(parsed.CORS_ORIGINS);
  },
  get ADMIN_EMAILS(): string[] {
    return splitOrigins(parsed.ADMIN_EMAILS ?? "");
  }
} as {
  PORT: number;
  HOST: string;
  LOG_LEVEL: string;
  JSON_BODY_LIMIT: string;
  LOG_FORMAT: string;
  API_BASE_URL: string | undefined;
  CORS_ORIGINS: string[];
  RATE_LIMIT_WINDOW_MS: number;
  RATE_LIMIT_MAX: number;
  STORIES_GENERATE_RATE_LIMIT_WINDOW_MS: number;
  STORIES_GENERATE_RATE_LIMIT_MAX: number;
  RATE_LIMIT_DISABLED: boolean;
  DAILY_FREE_STORY_LIMIT: number;
  DAILY_PREMIUM_STORY_LIMIT: number;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  OPENAI_API_KEY: string;
  OPENAI_MODEL: string;
  OPENAI_TEMPERATURE: number;
  OPENAI_IMAGE_MODEL: string;
  SWAGGER_ENABLED: boolean;
  SWAGGER_BASIC_AUTH_USERNAME: string;
  SWAGGER_BASIC_AUTH_PASSWORD: string;
  ADMIN_EMAILS: string[];
  SUPABASE_STORAGE_BUCKET_STORIES: string;
  TRUST_PROXY: boolean;
};

