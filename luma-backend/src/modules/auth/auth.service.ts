import { supabaseAdmin } from "../../config/supabase";
import { shouldFallbackParentsUpsertToUsersTable } from "../../utils/postgrestError";

export type AuthUser = { id: string; email?: string | null };

type UserRow = {
  id: string;
  email: string | null;
  created_at?: string;
};

class AuthService {
  async ensureUserRow(user: AuthUser): Promise<void> {
    // Keep backend app-specific user profile in sync with Supabase Auth.
    const email = user.email ?? null;

    const { error: parentsError } = await supabaseAdmin
      .from("parents")
      .upsert({ id: user.id, email }, { onConflict: "id" });

    if (!parentsError) return;

    // Eski Supabase projelerinde tablo adı hâlâ public.users olabilir (005 migration öncesi).
    if (shouldFallbackParentsUpsertToUsersTable(parentsError)) {
      const { error: usersError } = await supabaseAdmin
        .from("users")
        .upsert({ id: user.id, email }, { onConflict: "id" });
      if (usersError) throw usersError;
      return;
    }

    throw parentsError;
  }

  getMe(user: AuthUser): { user: { id: string; email: string | null } } {
    return {
      user: {
        id: user.id,
        email: user.email ?? null
      }
    };
  }
}

export const authService = new AuthService();

