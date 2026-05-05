import { AdminKitCatalogPanel } from "@/components/admin/admin-kit-catalog-panel";
import { loadKitCatalog } from "@/lib/catalog/load-shop-data";
import { colors } from "@/lib/theme/colors";

export default async function AdminKitItemsPage() {
  const items = await loadKitCatalog();

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight">Kit items</h1>
      <div className="mt-6">
        <AdminKitCatalogPanel initial={items} />
      </div>
      <p className="mt-6 text-xs" style={{ color: colors.textSecondary }}>
        Table <code>kit_catalog_items</code> — used by product kits and presets.
      </p>
    </div>
  );
}
