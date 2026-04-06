"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildStoryAssetPath = buildStoryAssetPath;
exports.buildStoryAssetMetadata = buildStoryAssetMetadata;
function sanitizeFileName(fileName) {
    const trimmed = fileName.trim();
    const base = trimmed.replace(/[^a-zA-Z0-9._-]/g, "_");
    // Prevent empty / extremely long names.
    if (base.length === 0)
        return "file";
    return base.slice(0, 120);
}
function buildStoryAssetPath(input) {
    const userId = input.userId.trim();
    const childId = input.childId.trim();
    const storyId = input.storyId.trim();
    const assetType = input.assetType;
    const fileName = sanitizeFileName(input.fileName);
    // Convention:
    // userId/childId/storyId/asset-type/file-name
    return `${userId}/${childId}/${storyId}/${assetType}/${fileName}`;
}
function buildStoryAssetMetadata(input) {
    return {
        user_id: input.userId,
        child_id: input.childId,
        story_id: input.storyId,
        asset_type: input.assetType
    };
}
//# sourceMappingURL=storagePaths.js.map