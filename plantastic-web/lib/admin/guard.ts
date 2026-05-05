import { fetchIsPlantasticAdmin } from "@/lib/admin/plantastic-admin";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";

export async function requirePlantasticAdminSupabase() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("SIGN_IN_REQUIRED");
  if (!(await fetchIsPlantasticAdmin(supabase))) throw new Error("NOT_ADMIN");
  return supabase;
}
