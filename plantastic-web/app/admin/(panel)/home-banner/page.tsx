import { AdminHomeBannerPanel } from "@/components/admin/admin-home-banner-panel";
import { homeBannerFallback, parseHomeBannerRow } from "@/lib/catalog/home-banner";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";
import { colors } from "@/lib/theme/colors";

export default async function AdminHomeBannerPage() {
  let banner = homeBannerFallback();

  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase
      .from("shop_home_banner")
      .select("*")
      .eq("id", 1)
      .maybeSingle();

    if (!error && data) {
      banner = parseHomeBannerRow(data as Record<string, unknown>);
    }
  } catch {
    /* use fallback */
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight">Home banner</h1>
      <div className="mt-6">
        <AdminHomeBannerPanel initial={banner} />
      </div>
      <p className="mt-6 text-xs" style={{ color: colors.textSecondary }}>
        Row <code>shop_home_banner</code> id=1 — carousel + heights + glass columns.
      </p>
    </div>
  );
}
