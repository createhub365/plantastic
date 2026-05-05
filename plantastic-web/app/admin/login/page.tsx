import { redirect } from "next/navigation";
import { AdminLoginForm } from "@/components/admin/admin-login-form";
import { fetchIsPlantasticAdmin } from "@/lib/admin/plantastic-admin";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";

export default async function AdminLoginPage() {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (user && (await fetchIsPlantasticAdmin(supabase))) {
      redirect("/admin");
    }
  } catch {
    /* missing env etc. — show login so user sees configure message from client */
  }

  return <AdminLoginForm />;
}
