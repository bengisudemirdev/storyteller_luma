"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.storageService = void 0;
const supabase_1 = require("../config/supabase");
const env_1 = require("../config/env");
const storagePaths_1 = require("../helpers/storagePaths");
class StorageService {
    async uploadStoryAsset(input) {
        const bucket = env_1.env.SUPABASE_STORAGE_BUCKET_STORIES;
        const objectPath = (0, storagePaths_1.buildStoryAssetPath)({
            userId: input.userId,
            childId: input.childId,
            storyId: input.storyId,
            assetType: input.assetType,
            fileName: input.fileName
        });
        const metadata = (0, storagePaths_1.buildStoryAssetMetadata)({
            userId: input.userId,
            childId: input.childId,
            storyId: input.storyId,
            assetType: input.assetType
        });
        const { error } = await supabase_1.supabaseStorage
            .from(bucket)
            .upload(objectPath, input.data, {
            contentType: input.contentType,
            upsert: input.upsert ?? false,
            cacheControl: "3600",
            metadata
        });
        if (error) {
            throw new Error(`Storage upload failed: ${error.message}`);
        }
        const { data } = supabase_1.supabaseStorage.from(bucket).getPublicUrl(objectPath);
        return { objectPath, publicUrl: data.publicUrl };
    }
    async uploadCatalogAsset(input) {
        const bucket = env_1.env.SUPABASE_STORAGE_BUCKET_STORIES;
        const objectPath = input.relativePath.replace(/^\/+/, "");
        const { error } = await supabase_1.supabaseStorage.from(bucket).upload(objectPath, input.data, {
            contentType: input.contentType,
            upsert: input.upsert ?? false,
            cacheControl: "86400"
        });
        if (error) {
            throw new Error(`Storage catalog upload failed: ${error.message}`);
        }
        const { data } = supabase_1.supabaseStorage.from(bucket).getPublicUrl(objectPath);
        return { objectPath, publicUrl: data.publicUrl };
    }
}
exports.storageService = new StorageService();
//# sourceMappingURL=storage.service.js.map