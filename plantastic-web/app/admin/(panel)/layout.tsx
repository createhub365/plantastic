import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminShell } from "@/components/admin/admin-shell";
import { signOutAdmin } from "@/lib/admin/actions";
import { fetchIsPlantasticAdmin } from "@/lib/admin/plantastic-admin";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";
import { colors } from "@/lib/theme/colors";

export default async function AdminPanelLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  let supabase;
  try {
    supabase = await createSupabaseServerClient();
  } catch {
    return (
      <div className="p-8" style={{ color: colors.textPrimary }}>
        <h1 className="text-xl font-semibold">Admin unavailable</h1>
        <p className="mt-2 max-w-md text-sm" style={{ color: colors.textSecondary }}>
          Supabase is not configured. Add NEXT_PUBLIC_SUPABASE_URL and
          NEXT_PUBLIC_SUPABASE_ANON_KEY to your environment.
        </p>
        <Link
          href="/"
          className="mt-6 inline-block rounded-lg px-4 py-2 text-sm font-medium text-white"
          style={{ backgroundColor: colors.primary }}
        >
          Back to shop
        </Link>
      </div>
    );
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/admin/login");

  const isAdmin = await fetchIsPlantasticAdmin(supabase);

  if (!isAdmin) {
    return (
      <div className="mx-auto max-w-md p-8" style={{ color: colors.textPrimary }}>
        <h1 className="text-xl font-semibold">Access denied</h1>
        <p className="mt-2 text-sm" style={{ color: colors.textSecondary }}>
          Signed in as {user.email ?? user.id}, but this account is not marked as admin in{" "}
          <code className="text-xs">plantastic_staff</code>.
        </p>
        <div className="mt-6 flex flex-wrap gap-3">
          <form action={signOutAdmin}>
            <button
              type="submit"
              className="rounded-lg border px-4 py-2 text-sm font-medium"
              style={{ borderColor: colors.border }}
            >
              Sign out
            </button>
          </form>
          <Link
            href="/"
            className="rounded-lg px-4 py-2 text-sm font-medium text-white"
            style={{ backgroundColor: colors.primary }}
          >
            Back to shop
          </Link>
        </div>
      </div>
    );
  }

  return <AdminShell userEmail={user.email ?? ""}>{children}</AdminShell>;
}
