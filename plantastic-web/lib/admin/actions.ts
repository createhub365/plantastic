"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { fetchIsPlantasticAdmin } from "@/lib/admin/plantastic-admin";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";

export async function signOutAdmin() {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();
  revalidatePath("/admin", "layout");
  redirect("/admin/login");
}
