const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY,
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false,
        },
        global: {
            fetch: (url, options) => {
                return fetch(url, { ...options, signal: AbortSignal.timeout(30000) });
            }
        }
    }
);

module.exports = { supabase };