import { supabaseAdmin } from "../../config/supabase";
import { ApiError } from "../../utils/apiError";

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

    const { error } = await supabaseAdmin
      .from("parents")
      .upsert({ id: user.id, email }, { onConflict: "id" });

    if (error) {
      const isProd = process.env.NODE_ENV === "production";
      throw new ApiError(
        500,
        "USER_PROFILE_SYNC_FAILED",
        isProd ? "Could not sync user profile" : error.message,
        isProd
          ? undefined
          : { supabaseCode: error.code, details: error.details, hint: error.hint }
      );
    }
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

