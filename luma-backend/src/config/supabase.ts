import { createClient } from "@supabase/supabase-js";
import { env } from "./env";

export const supabaseAdmin = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    // Avoid persisting any sessions on the server.
    persistSession: false
  },
  global: {
    headers: {
      "X-Luma-Client": "luma-backend"
    }
  }
});

// Storage client is available on the same service-role client.
export const supabaseStorage = supabaseAdmin.storage;

