/**
 * Read-only Supabase PostgREST via fetch (no extra npm package).
 * Uses the same anon key as the Flutter app.
 */

type RestError = { message: string; code?: string };

function buildHeaders(anonKey: string): HeadersInit {
  return {
    apikey: anonKey,
    Authorization: `Bearer ${anonKey}`,
    Accept: "application/json",
    "Content-Type": "application/json",
    Prefer: "return=representation",
  };
}

/** Inserts without asking PostgREST to return rows (avoids RLS SELECT on `RETURNING`). */
function buildInsertHeaders(anonKey: string): HeadersInit {
  return {
    apikey: anonKey,
    Authorization: `Bearer ${anonKey}`,
    Accept: "application/json",
    "Content-Type": "application/json",
    Prefer: "return=minimal",
  };
}

export async function restInsert(
  table: string,
  row: Record<string, unknown>,
): Promise<{ ok: boolean; status: number; bodyText: string }> {
  const cfg = getSupabasePublicConfig();
  if (!cfg) {
    return { ok: false, status: 503, bodyText: "Missing Supabase env" };
  }
  const href = `${cfg.url.replace(/\/$/, "")}/rest/v1/${table}`;
  try {
    const res = await fetch(href, {
      method: "POST",
      headers: buildInsertHeaders(cfg.anonKey),
      body: JSON.stringify(row),
    });
    const bodyText = await res.text();
    return { ok: res.ok, status: res.status, bodyText };
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return { ok: false, status: 502, bodyText: message };
  }
}

export function getSupabasePublicConfig(): {
  url: string;
  anonKey: string;
} | null {
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
  if (!url || !anonKey) return null;
  return { url, anonKey };
}

export async function restSelect<T extends Record<string, unknown>>(
  table: string,
  query: string,
): Promise<{ data: T[] | null; error: RestError | null }> {
  const cfg = getSupabasePublicConfig();
  if (!cfg) {
    return { data: null, error: { message: "Missing Supabase env" } };
  }

  const href = `${cfg.url.replace(/\/$/, "")}/rest/v1/${table}?${query}`;

  try {
    const res = await fetch(href, {
      method: "GET",
      headers: buildHeaders(cfg.anonKey),
      next: { revalidate: 120 },
    });

    if (!res.ok) {
      const text = await res.text();
      return {
        data: null,
        error: { message: text || res.statusText, code: String(res.status) },
      };
    }

    const json = (await res.json()) as T[];
    return { data: Array.isArray(json) ? json : [], error: null };
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return { data: null, error: { message } };
  }
}

export async function restSelectSingle<T extends Record<string, unknown>>(
  table: string,
  query: string,
): Promise<{ data: T | null; error: RestError | null }> {
  const { data, error } = await restSelect<T>(table, query);
  if (error) return { data: null, error };
  return { data: data?.[0] ?? null, error: null };
}
