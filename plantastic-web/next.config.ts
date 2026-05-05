import type { NextConfig } from "next";

/**
 * Flutter `plantastic/.env` uses SUPABASE_* only. Browser code can't read those —
 * Next inlines NEXT_PUBLIC_* into the bundle. Mirror them here so one .env.local
 * file can use the Flutter names only.
 */
function supabasePublicFromEnv(): { url: string; anonKey: string } {
  const url = (
    process.env.NEXT_PUBLIC_SUPABASE_URL ??
    process.env.SUPABASE_URL ??
    ""
  ).trim();
  const anonKey = (
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
    process.env.SUPABASE_ANON_KEY ??
    ""
  ).trim();
  return { url, anonKey };
}

const { url: supabaseUrl, anonKey: supabaseAnonKey } =
  supabasePublicFromEnv();

const nextConfig: NextConfig = {
  env: {
    NEXT_PUBLIC_SUPABASE_URL: supabaseUrl,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: supabaseAnonKey,
  },
};

export default nextConfig;
