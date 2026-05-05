import { AdminProductEditor } from "@/components/admin/admin-product-editor";
import { makeEmptyDraftProduct } from "@/lib/admin/product-editor-defaults";
import { loadHighlightCatalog } from "@/lib/catalog/load-shop-data";

export default async function AdminNewProductPage() {
  const highlightCatalog = await loadHighlightCatalog();

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold tracking-tight">New product</h1>
      <AdminProductEditor initial={makeEmptyDraftProduct()} highlightCatalog={highlightCatalog} />
    </div>
  );
}
