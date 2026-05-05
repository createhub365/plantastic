import { AdminKitPresetsPanel } from "@/components/admin/admin-kit-presets-panel";
import { parseKitPresetFromRow } from "@/lib/catalog/kit-preset";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";
import { colors } from "@/lib/theme/colors";

export default async function AdminKitPresetsPage() {
  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase
      .from("kit_presets")
      .select("*")
      .order("sort_order", { ascending: true });

    if (error) {
      return (
        <div>
          <h1 className="text-2xl font-semibold">Kit presets</h1>
          <p className="mt-2 text-sm text-red-600">{error.message}</p>
        </div>
      );
    }

    const presets = (Array.isArray(data) ? data : []).map((r) =>
      parseKitPresetFromRow(r as Record<string, unknown>),
    );

    return (
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Kit presets</h1>
        <div className="mt-6">
          <AdminKitPresetsPanel initial={presets} />
        </div>
        <p className="mt-6 text-xs" style={{ color: colors.textSecondary }}>
          Table <code>kit_presets</code> — bundle lists of catalogue UUIDs.
        </p>
      </div>
    );
  } catch (e) {
    return (
      <div>
        <h1 className="text-2xl font-semibold">Kit presets</h1>
        <p className="mt-2">{e instanceof Error ? e.message : "Error"}</p>
      </div>
    );
  }
}
