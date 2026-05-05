"use client";

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import { getSupabasePublishableConfig } from "@/lib/supabase/env";

export function createSupabaseBrowserClient(): SupabaseClient {
  const { url, anonKey } = getSupabasePublishableConfig();

  if (!url || !anonKey) {
    throw new Error(
      "Missing Supabase URL / anon key. In .env.local set SUPABASE_URL + SUPABASE_ANON_KEY (Flutter names) or NEXT_PUBLIC_*; restart `next dev`.",
    );
  }

  return createBrowserClient(url, anonKey);
}
