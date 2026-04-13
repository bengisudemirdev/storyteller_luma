/**
 * Klasik masal kapaklarını OpenAI images.generate ile üretir ve Supabase Storage’a yükler.
 * Çıktı URL’leri `classic-tales/{id}/cover.png` altında olur; iOS’ta CLASSIC_TALE_COVERS_BASE_URL
 * bu bucket’taki `classic-tales` klasörünün public tabanı olmalı (sonunda / olmadan).
 *
 * Çalıştır: npm run seed:classic-covers  (luma-backend dizininde, .env dolu)
 */
import "dotenv/config";

import { env } from "../src/config/env";
import { storyCoverImageService } from "../src/services/storyCoverImage.service";
import { CLASSIC_TALES_WITH_FULL_STORY } from "./classic-tales-full-stories";

async function main(): Promise<void> {
  // eslint-disable-next-line no-console
  console.log(JSON.stringify({ event: "seed.classic_covers.started", count: CLASSIC_TALES_WITH_FULL_STORY.length }));
  for (const t of CLASSIC_TALES_WITH_FULL_STORY) {
    const url = await storyCoverImageService.generateUploadClassicTaleCover({
      taleId: t.taleId,
      title: t.title,
      teaser: t.teaser,
      fullStory: t.fullStory
    });
    // eslint-disable-next-line no-console
    console.log(JSON.stringify({ event: "seed.classic_covers.item_ok", taleId: t.taleId, url }));
  }
  const baseHint = `${env.SUPABASE_URL.replace(/\/+$/, "")}/storage/v1/object/public/${env.SUPABASE_STORAGE_BUCKET_STORIES}/classic-tales`;
  // eslint-disable-next-line no-console
  console.log(JSON.stringify({ event: "seed.classic_covers.done", result: "ok" }));
  // eslint-disable-next-line no-console
  console.log(
    "\nLuma/Config/.env içine ekleyin (sonunda / yok):\nCLASSIC_TALE_COVERS_BASE_URL=" + baseHint + "\n"
  );
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(JSON.stringify({ event: "seed.classic_covers.failed", message: err instanceof Error ? err.message : String(err) }));
  process.exit(1);
});
