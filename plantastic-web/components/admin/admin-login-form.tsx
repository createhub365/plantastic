"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser-client";
import { colors } from "@/lib/theme/colors";

export function AdminLoginForm() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setPending(true);
    const form = e.currentTarget;
    const fd = new FormData(form);
    const email = String(fd.get("email") ?? "").trim();
    const password = String(fd.get("password") ?? "");

    try {
      const supabase = createSupabaseBrowserClient();
      const { error: signErr } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (signErr) {
        setError(signErr.message);
        setPending(false);
        return;
      }

      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        setError("Could not read session after sign-in.");
        setPending(false);
        return;
      }

      const { data: staff, error: staffErr } = await supabase
        .from("plantastic_staff")
        .select("is_admin")
        .eq("user_id", user.id)
        .maybeSingle();

      if (staffErr || !staff || (staff as { is_admin?: boolean }).is_admin !== true) {
        await supabase.auth.signOut();
        setError("This account is not authorized for admin.");
        setPending(false);
        return;
      }

      router.replace("/admin");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed.");
      setPending(false);
    }
  }

  return (
    <div
      className="w-full max-w-sm rounded-2xl border p-6 shadow-sm"
      style={{
        borderColor: colors.border,
        backgroundColor: colors.card,
        color: colors.textPrimary,
      }}
    >
      <h1 className="text-xl font-semibold">Admin sign in</h1>
      <p className="mt-1 text-sm" style={{ color: colors.textSecondary }}>
        Use your Plantastic staff account.
      </p>
      <form className="mt-6 space-y-4" onSubmit={onSubmit}>
        <div>
          <label htmlFor="admin-email" className="block text-sm font-medium">
            Email
          </label>
          <input
            id="admin-email"
            name="email"
            type="email"
            autoComplete="email"
            required
            className="mt-1 w-full rounded-lg border px-3 py-2 text-sm outline-none focus:ring-2"
            style={{ borderColor: colors.border }}
          />
        </div>
        <div>
          <label htmlFor="admin-password" className="block text-sm font-medium">
            Password
          </label>
          <input
            id="admin-password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            className="mt-1 w-full rounded-lg border px-3 py-2 text-sm outline-none focus:ring-2"
            style={{ borderColor: colors.border }}
          />
        </div>
        {error ? (
          <p className="text-sm text-red-600" role="alert">
            {error}
          </p>
        ) : null}
        <button
          type="submit"
          disabled={pending}
          className="w-full rounded-lg py-2.5 text-sm font-semibold text-white disabled:opacity-60"
          style={{ backgroundColor: colors.primary }}
        >
          {pending ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </div>
  );
}
