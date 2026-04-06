/**
 * PostgREST / Supabase JS hatalarını ayırt etmek için (PostgrestError extends Error).
 */
export function isPostgrestLikeError(err: unknown): err is Error & { code: string; details?: string; hint?: string } {
  if (!(err instanceof Error)) return false;
  const o = err as Error & { code?: unknown };
  return typeof o.code === "string" && o.code.length > 0;
}

/**
 * `public.parents` henüz yok, eski şemada `public.users` varsa upsert'i oraya taşı.
 * PGRST205: tablo şema önbelleğinde yok vb.
 */
export function shouldFallbackParentsUpsertToUsersTable(err: unknown): boolean {
  if (!isPostgrestLikeError(err)) return false;
  const code = err.code;
  const msg = (err.message ?? "").toLowerCase();
  if (code === "PGRST205") return true;
  if (msg.includes("parents") && (msg.includes("could not find") || msg.includes("does not exist"))) return true;
  if (msg.includes("relation") && msg.includes("parents") && msg.includes("does not exist")) return true;
  return false;
}
