"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.swaggerUi = exports.swaggerSpec = exports.swaggerBasicAuthMiddleware = void 0;
const path_1 = __importDefault(require("path"));
const swagger_jsdoc_1 = __importDefault(require("swagger-jsdoc"));
const swagger_ui_express_1 = __importDefault(require("swagger-ui-express"));
exports.swaggerUi = swagger_ui_express_1.default;
const express_basic_auth_1 = __importDefault(require("express-basic-auth"));
const env_1 = require("./env");
const docsUsers = {
    [env_1.env.SWAGGER_BASIC_AUTH_USERNAME]: env_1.env.SWAGGER_BASIC_AUTH_PASSWORD
};
exports.swaggerBasicAuthMiddleware = (0, express_basic_auth_1.default)({
    users: docsUsers,
    challenge: true
});
const apiBaseUrl = env_1.env.API_BASE_URL ?? "http://localhost:3001";
// Keep path generation deterministic (no secret examples).
const swaggerDefinition = {
    openapi: "3.0.0",
    info: {
        title: "Luma Backend API",
        version: "1.0.0",
        description: "Production-ready Express + TypeScript backend skeleton."
    },
    servers: [{ url: apiBaseUrl }],
    tags: [
        { name: "Auth" },
        { name: "Children" },
        { name: "Stories" },
        { name: "Usage" },
        { name: "Subscription" }
    ],
    components: {
        securitySchemes: {
            BearerAuth: {
                type: "http",
                scheme: "bearer",
                bearerFormat: "JWT",
                description: "Supabase Auth **access_token** (oturum JWT). Sadece `eyJ...` kısmını yapıştırın; `Bearer ` yazmayın (Swagger zaten ekler). Anon/service role key geçerli değildir. Token, backend .env içindeki SUPABASE_URL ile aynı projeden olmalıdır."
            }
        },
        schemas: {
            AuthMeResponse: {
                type: "object",
                properties: {
                    success: { type: "boolean", example: true },
                    data: {
                        type: "object",
                        properties: {
                            user: {
                                type: "object",
                                properties: {
                                    id: { type: "string" },
                                    email: { type: "string", nullable: true }
                                }
                            }
                        }
                    }
                }
            },
            GenerateStoryRequest: {
                type: "object",
                required: ["childId", "theme"],
                description: "Story-specific only. Reading age, fears, persistent interests, tone/length come from the child record.",
                properties: {
                    childId: { type: "string" },
                    theme: { type: "string" },
                    language: { type: "string", nullable: true },
                    extraContext: { type: "string", nullable: true, maxLength: 500 },
                    selectedInterests: { type: "array", items: { type: "string" }, maxItems: 25 },
                    storyGoal: { type: "string", nullable: true, maxLength: 300 }
                }
            },
            ChildCreateRequest: {
                type: "object",
                required: ["name"],
                properties: {
                    name: { type: "string" },
                    age: { type: "integer", nullable: true, minimum: 0, maximum: 15 },
                    profile: { type: "string", nullable: true },
                    avatar_emoji: { type: "string", maxLength: 16 },
                    interests: { type: "array", items: { type: "string" }, maxItems: 25 },
                    fears: { type: "array", items: { type: "string" }, maxItems: 25 }
                }
            },
            ChildPatchRequest: {
                type: "object",
                properties: {
                    name: { type: "string" },
                    age: { type: "integer", nullable: true, minimum: 0, maximum: 15 },
                    profile: { type: "string", nullable: true },
                    avatar_emoji: { type: "string", nullable: true, maxLength: 16 },
                    interests: { type: "array", nullable: true, items: { type: "string" }, maxItems: 25 },
                    fears: { type: "array", nullable: true, items: { type: "string" }, maxItems: 25 }
                }
            },
            Child: {
                type: "object",
                properties: {
                    id: { type: "string" },
                    user_id: { type: "string" },
                    name: { type: "string" },
                    age: { type: "integer", nullable: true },
                    profile: { type: "string", nullable: true },
                    avatar_emoji: { type: "string" },
                    interests: { type: "array", items: { type: "string" } },
                    fears: { type: "array", items: { type: "string" } },
                    created_at: { type: "string" },
                    updated_at: { type: "string" }
                }
            },
            StoryGenerateResponse: {
                type: "object",
                properties: {
                    success: { type: "boolean", example: true },
                    data: {
                        type: "object",
                        properties: {
                            story: {
                                type: "object",
                                properties: {
                                    id: { type: "string" },
                                    title: { type: "string" },
                                    content: { type: "string" },
                                    theme: { type: "string" },
                                    age_group: { type: "string" },
                                    language: { type: "string", nullable: true },
                                    cover_image_url: { type: "string", nullable: true },
                                    audio_url: { type: "string", nullable: true }
                                }
                            }
                        }
                    }
                }
            },
            ErrorResponse: {
                type: "object",
                properties: {
                    success: { type: "boolean", example: false },
                    error: {
                        type: "object",
                        properties: {
                            code: { type: "string" },
                            message: { type: "string" },
                            details: { type: "object", nullable: true }
                        }
                    }
                }
            }
        }
    },
    security: [{ BearerAuth: [] }],
    paths: {
        "/v1/auth/me": {
            post: {
                tags: ["Auth"],
                summary: "Get current user",
                responses: {
                    "200": { description: "OK" },
                    "401": { description: "Unauthorized" },
                    "500": { description: "Internal error", content: { "application/json": { schema: { $ref: "#/components/schemas/ErrorResponse" } } } }
                }
            }
        },
        "/v1/children": {
            post: {
                tags: ["Children"],
                summary: "Create child",
                requestBody: {
                    required: true,
                    content: {
                        "application/json": { schema: { $ref: "#/components/schemas/ChildCreateRequest" } }
                    }
                },
                responses: {
                    "200": { description: "OK" }
                }
            },
            get: {
                tags: ["Children"],
                summary: "List children",
                responses: {
                    "200": { description: "OK" }
                }
            }
        },
        "/v1/children/{id}": {
            patch: {
                tags: ["Children"],
                summary: "Update child",
                parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
                requestBody: {
                    required: true,
                    content: {
                        "application/json": { schema: { $ref: "#/components/schemas/ChildPatchRequest" } }
                    }
                },
                responses: {
                    "200": { description: "OK" },
                    "404": { description: "Not found" }
                }
            },
            delete: {
                tags: ["Children"],
                summary: "Delete child",
                parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
                responses: {
                    "200": { description: "OK" },
                    "404": { description: "Not found" }
                }
            }
        },
        "/v1/stories": {
            get: {
                tags: ["Stories"],
                summary: "List stories",
                parameters: [
                    {
                        name: "limit",
                        in: "query",
                        schema: { type: "integer", default: 20, minimum: 1, maximum: 100 },
                        required: false
                    }
                ],
                responses: {
                    "200": { description: "OK" },
                    "401": { description: "Unauthorized" }
                }
            }
        },
        "/v1/stories/{id}": {
            get: {
                tags: ["Stories"],
                summary: "Get story by id",
                parameters: [
                    { name: "id", in: "path", required: true, schema: { type: "string" } }
                ],
                responses: {
                    "200": { description: "OK" },
                    "404": { description: "Not found" }
                }
            }
        },
        "/v1/stories/generate": {
            post: {
                tags: ["Stories"],
                summary: "Generate a story with OpenAI",
                requestBody: {
                    required: true,
                    content: {
                        "application/json": { schema: { $ref: "#/components/schemas/GenerateStoryRequest" } }
                    }
                },
                responses: {
                    "200": { description: "OK", content: { "application/json": { schema: { $ref: "#/components/schemas/StoryGenerateResponse" } } } },
                    "401": { description: "Unauthorized" },
                    "429": { description: "Rate limit / usage limit" }
                }
            }
        },
        "/v1/usage": {
            get: {
                tags: ["Usage"],
                summary: "Get daily usage",
                responses: {
                    "200": { description: "OK" }
                }
            }
        },
        "/v1/subscription/status": {
            get: {
                tags: ["Subscription"],
                summary: "Get subscription status",
                responses: {
                    "200": { description: "OK" }
                }
            }
        }
    }
};
// Use swagger-jsdoc (even though the definition is explicit) to keep integration consistent.
const spec = (0, swagger_jsdoc_1.default)({
    definition: swaggerDefinition,
    apis: [path_1.default.join(process.cwd(), "src/modules/**/*.routes.ts"), path_1.default.join(process.cwd(), "src/modules/**/*.ts")]
});
exports.swaggerSpec = spec;
//# sourceMappingURL=swagger.js.map