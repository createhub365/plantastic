import { notFound } from "next/navigation";
import { AdminProductEditor } from "@/components/admin/admin-product-editor";
import {
  loadHighlightCatalog,
  loadShopProducts,
} from "@/lib/catalog/load-shop-data";
import { productFromRow } from "@/lib/catalog/parse-product";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";

export default async function AdminEditProductPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  let product = null;

  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase
      .from("products")
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (!error && data) {
      product = productFromRow(data as Record<string, unknown>);
    }
  } catch {
    const seeds = await loadShopProducts();
    product = seeds.find((p) => p.id === id) ?? null;
  }

  if (!product?.id) notFound();

  const highlightCatalog = await loadHighlightCatalog();

  return (
    <div>
      <h1 className="sr-only">Edit product</h1>
      <AdminProductEditor initial={product} highlightCatalog={highlightCatalog} />
    </div>
  );
}
