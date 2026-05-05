import type { SupabaseClient } from "@supabase/supabase-js";

/** Mirrors Flutter `AdminCatalogService.fetchIsAdmin()` — row in `plantastic_staff`. */
export async function fetchIsPlantasticAdmin(
  supabase: SupabaseClient,
): Promise<boolean> {
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return false;

  const { data, error } = await supabase
    .from("plantastic_staff")
    .select("is_admin")
    .eq("user_id", user.id)
    .maybeSingle();

  if (error || data == null) return false;
  const row = data as { is_admin?: boolean };
  return row.is_admin === true;
}
