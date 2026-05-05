import { AdminHighlightsPanel } from "@/components/admin/admin-highlights-panel";
import { loadHighlightCatalog } from "@/lib/catalog/load-shop-data";
import { colors } from "@/lib/theme/colors";

export default async function AdminHighlightsPage() {
  const tags = await loadHighlightCatalog();

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight">Highlights</h1>
      <div className="mt-6">
        <AdminHighlightsPanel initial={tags} />
      </div>
      <p className="mt-6 text-xs" style={{ color: colors.textSecondary }}>
        Table <code>highlight_tags</code> — shopper chips + modal copy.
      </p>
    </div>
  );
}
