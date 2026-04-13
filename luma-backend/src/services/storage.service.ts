import { supabaseStorage } from "../config/supabase";
import { env } from "../config/env";
import type { StoryAssetType } from "../helpers/storagePaths";
import { buildStoryAssetMetadata, buildStoryAssetPath } from "../helpers/storagePaths";

export type UploadStoryAssetInput = {
  userId: string;
  childId: string;
  storyId: string;
  assetType: StoryAssetType;
  fileName: string;
  contentType: string;
  // Buffer is expected for Node runtime.
  data: Buffer;
  upsert?: boolean;
};

export type UploadStoryAssetResult = {
  objectPath: string;
  publicUrl: string;
};

export type UploadCatalogAssetInput = {
  /** Bucket root-relative path, e.g. `classic-tales/snow-white/cover.png` */
  relativePath: string;
  contentType: string;
  data: Buffer;
  upsert?: boolean;
};

class StorageService {
  async uploadStoryAsset(input: UploadStoryAssetInput): Promise<UploadStoryAssetResult> {
    const bucket = env.SUPABASE_STORAGE_BUCKET_STORIES;

    const objectPath = buildStoryAssetPath({
      userId: input.userId,
      childId: input.childId,
      storyId: input.storyId,
      assetType: input.assetType,
      fileName: input.fileName
    });

    const metadata = buildStoryAssetMetadata({
      userId: input.userId,
      childId: input.childId,
      storyId: input.storyId,
      assetType: input.assetType
    });

    const { error } = await supabaseStorage
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

    const { data } = supabaseStorage.from(bucket).getPublicUrl(objectPath);
    return { objectPath, publicUrl: data.publicUrl };
  }

  async uploadCatalogAsset(input: UploadCatalogAssetInput): Promise<UploadStoryAssetResult> {
    const bucket = env.SUPABASE_STORAGE_BUCKET_STORIES;
    const objectPath = input.relativePath.replace(/^\/+/, "");

    const { error } = await supabaseStorage.from(bucket).upload(objectPath, input.data, {
      contentType: input.contentType,
      upsert: input.upsert ?? false,
      cacheControl: "86400"
    });

    if (error) {
      throw new Error(`Storage catalog upload failed: ${error.message}`);
    }

    const { data } = supabaseStorage.from(bucket).getPublicUrl(objectPath);
    return { objectPath, publicUrl: data.publicUrl };
  }
}

export const storageService = new StorageService();

