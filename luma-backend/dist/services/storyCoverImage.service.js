"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.storyCoverImageService = void 0;
exports.buildStoryBookCoverPrompt = buildStoryBookCoverPrompt;
exports.buildClassicTaleCoverPrompt = buildClassicTaleCoverPrompt;
const openai_1 = require("../config/openai");
const env_1 = require("../config/env");
const supabase_1 = require("../config/supabase");
const promptSanitizer_1 = require("../helpers/promptSanitizer");
const structuredLog_1 = require("../utils/structuredLog");
const storage_service_1 = require("./storage.service");
function stripPageMarkers(story) {
    return story.replace(/^\s*\d+\.\s*/gm, " ").replace(/\s+/g, " ").trim();
}
function excerptForCover(story, maxChars) {
    const cleaned = stripPageMarkers(story).slice(0, maxChars);
    return (0, promptSanitizer_1.sanitizeForPrompt)(cleaned, maxChars) || "a gentle bedtime scene";
}
function buildStoryBookCoverPrompt(input) {
    const title = (0, promptSanitizer_1.sanitizeForPrompt)(input.title, 100);
    const theme = (0, promptSanitizer_1.sanitizeForPrompt)(input.theme, 80);
    const excerpt = (0, promptSanitizer_1.sanitizeForPrompt)(input.storyExcerpt.slice(0, 900), 900);
    return [
        "Children's picture book COVER illustration (single scene), vertical composition.",
        "Warm watercolor storybook style; cozy bedtime palette; soft diffused light.",
        "Absolutely no text, letters, numbers, logos, signatures, or watermarks in the image.",
        "Kid-safe for ages 3+, friendly and calm, non-scary, no weapons, no horror.",
        `Mood inspired by title concept """${title}""", theme """${theme}"""; storytelling language context: """${(0, promptSanitizer_1.sanitizeForPrompt)(input.language, 32)}""".`,
        `Story-derived visual cues — one coherent scene matching THIS tale (symbolic only, no readable text): """${excerpt}""".`
    ].join(" ");
}
/**
 * Klasik masal kapağı: başlık + kısa slogan + metnin başından türetilen özet (içerikle uyumlu tek sahne).
 */
function buildClassicTaleCoverPrompt(input) {
    const title = (0, promptSanitizer_1.sanitizeForPrompt)(input.title, 100);
    const teaser = (0, promptSanitizer_1.sanitizeForPrompt)(input.teaser, 200);
    const excerpt = (0, promptSanitizer_1.sanitizeForPrompt)(input.storyExcerpt.slice(0, 1200), 1200);
    return [
        "Children's picture book COVER for ONE scene from a classic fairy tale, vertical composition.",
        "Warm watercolor / gouache storybook style; gentle bedtime mood; soft light.",
        "Absolutely no text, letters, numbers, logos, signatures, or watermarks in the image.",
        "Kid-safe, calm, non-frightening; culturally neutral friendly characters; no weapons, no gore.",
        `Tale title (mood only — do not paint these words): """${title}""".`,
        `Short tagline (atmosphere only): """${teaser}""".`,
        "Choose ONE concrete visual moment or setting that fits THIS specific story (avoid a generic unrelated forest/castle).",
        `Story-derived visual cues (symbolic only; no readable text from the passage): """${excerpt}""".`
    ].join(" ");
}
async function generateCoverImageBuffer(prompt) {
    const model = env_1.env.OPENAI_IMAGE_MODEL.trim();
    if (model === "dall-e-3") {
        const resp = await openai_1.openai.images.generate({
            model: "dall-e-3",
            prompt: prompt.slice(0, 4000),
            size: "1024x1792",
            quality: "standard",
            style: "natural",
            response_format: "b64_json",
            n: 1
        });
        const b64 = resp.data?.[0]?.b64_json;
        if (!b64)
            throw new Error("OpenAI images.generate: empty b64_json for dall-e-3");
        return { buffer: Buffer.from(b64, "base64"), contentType: "image/png", fileName: "cover.png" };
    }
    const resp = await openai_1.openai.images.generate({
        model: "gpt-image-1",
        prompt: prompt.slice(0, 8000),
        size: "1024x1536",
        output_format: "png",
        n: 1
    });
    const b64 = resp.data?.[0]?.b64_json;
    if (!b64)
        throw new Error("OpenAI images.generate: empty b64_json for gpt-image-1");
    return { buffer: Buffer.from(b64, "base64"), contentType: "image/png", fileName: "cover.png" };
}
class StoryCoverImageService {
    async generateUploadAndAttachToStory(input) {
        const requestId = input.requestId ?? "unknown";
        const route = input.route ?? "POST /v1/stories/generate";
        const baseFields = {
            requestId,
            route,
            userId: input.userId,
            childId: input.childId,
            storyId: input.storyId,
            action: "stories.cover"
        };
        const excerpt = excerptForCover(input.content, 1600);
        const prompt = buildStoryBookCoverPrompt({
            title: input.title,
            theme: input.theme,
            language: input.language,
            storyExcerpt: excerpt
        });
        const t0 = Date.now();
        (0, structuredLog_1.logStructured)("info", "stories.cover.openai_started", { ...baseFields, result: "started" });
        const { buffer, contentType, fileName } = await generateCoverImageBuffer(prompt);
        (0, structuredLog_1.logStructured)("info", "stories.cover.openai_done", {
            ...baseFields,
            durationMs: Date.now() - t0,
            bytes: buffer.length,
            result: "ok"
        });
        const { publicUrl } = await storage_service_1.storageService.uploadStoryAsset({
            userId: input.userId,
            childId: input.childId,
            storyId: input.storyId,
            assetType: "cover",
            fileName,
            contentType,
            data: buffer,
            upsert: true
        });
        const { error } = await supabase_1.supabaseAdmin
            .from("stories")
            .update({ cover_image_url: publicUrl })
            .eq("id", input.storyId)
            .eq("user_id", input.userId);
        if (error) {
            (0, structuredLog_1.logStructured)("error", "stories.cover.db_update_failed", {
                ...baseFields,
                category: "database",
                message: error.message,
                result: "error"
            });
            throw error;
        }
        (0, structuredLog_1.logStructured)("info", "stories.cover.completed", { ...baseFields, result: "success" });
        return publicUrl;
    }
    async generateUploadClassicTaleCover(input) {
        const storyExcerpt = excerptForCover(input.fullStory, 1400);
        const prompt = buildClassicTaleCoverPrompt({
            title: input.title,
            teaser: input.teaser,
            storyExcerpt
        });
        const { buffer, contentType, fileName } = await generateCoverImageBuffer(prompt);
        const { publicUrl } = await storage_service_1.storageService.uploadCatalogAsset({
            relativePath: `classic-tales/${sanitizeCatalogSegment(input.taleId)}/${fileName}`,
            contentType,
            data: buffer,
            upsert: true
        });
        return publicUrl;
    }
}
function sanitizeCatalogSegment(id) {
    const s = id.trim().replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 80);
    return s.length > 0 ? s : "tale";
}
exports.storyCoverImageService = new StoryCoverImageService();
//# sourceMappingURL=storyCoverImage.service.js.map