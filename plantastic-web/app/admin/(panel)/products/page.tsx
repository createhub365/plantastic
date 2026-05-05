import { AdminProductsPanel } from "@/components/admin/admin-products-panel";
import { productFromRow } from "@/lib/catalog/parse-product";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";
import { colors } from "@/lib/theme/colors";

export default async function AdminProductsPage() {
  let rows: Record<string, unknown>[] = [];

  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase
      .from("products")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) {
      return (
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Products</h1>
          <p className="mt-2 text-sm text-red-600">{error.message}</p>
        </div>
      );
    }
    rows =
      Array.isArray(data) ? data.map((r) => r as Record<string, unknown>) : [];
  } catch {
    return (
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Products</h1>
        <p className="mt-2 text-sm" style={{ color: colors.textSecondary }}>
          Supabase unavailable — check NEXT_PUBLIC_* env.
        </p>
      </div>
    );
  }

  const products = rows.map((r) => productFromRow(r)).filter((p) => p.id);

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight">Products</h1>
      <p className="mt-1 text-sm" style={{ color: colors.textSecondary }}>
        Search, filter, bulk-delete, toggle stock / shop visibility, or open full editor (kits,
        highlights, gallery, same DB shape as Flutter).
      </p>
      <div className="mt-6">
        <AdminProductsPanel products={products} />
      </div>
    </div>
  );
}
