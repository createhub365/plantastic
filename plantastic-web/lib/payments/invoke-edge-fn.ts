import { getSupabasePublicConfig } from "@/lib/supabase/rest";

/**
 * Calls a Supabase Edge Function with the anon key (same as Flutter `functions.invoke`).
 */
export async function invokeSupabaseEdgeFunction(
  name: string,
  body: unknown,
): Promise<{ ok: boolean; status: number; data: unknown }> {
  const cfg = getSupabasePublicConfig();
  if (!cfg) {
    return { ok: false, status: 503, data: { error: "Supabase not configured" } };
  }
  const url = `${cfg.url.replace(/\/$/, "")}/functions/v1/${name.replace(/^\//, "")}`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        apikey: cfg.anonKey,
        Authorization: `Bearer ${cfg.anonKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body ?? {}),
    });
    const data = await res.json().catch(() => ({}));
    return { ok: res.ok, status: res.status, data };
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return {
      ok: false,
      status: 502,
      data: { error: message },
    };
  }
}
