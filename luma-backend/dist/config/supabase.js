"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabaseStorage = exports.supabaseAdmin = void 0;
const supabase_js_1 = require("@supabase/supabase-js");
const env_1 = require("./env");
exports.supabaseAdmin = (0, supabase_js_1.createClient)(env_1.env.SUPABASE_URL, env_1.env.SUPABASE_SERVICE_ROLE_KEY, {
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
exports.supabaseStorage = exports.supabaseAdmin.storage;
//# sourceMappingURL=supabase.js.map