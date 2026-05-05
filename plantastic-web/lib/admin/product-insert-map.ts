import type { ProductKitLine, ShopProduct } from "@/lib/catalog/types";

function kitLineToDbJson(k: ProductKitLine) {
  const o: Record<string, unknown> = {
    line_id: k.lineId,
    label: k.label.trim(),
    catalog_ids: k.catalogIds,
    price_inr: k.priceInr,
  };
  if (k.presetId != null && `${k.presetId}`.trim() !== "") {
    o.preset_id = `${k.presetId}`.trim();
  }
  if (k.snapshotLines.length > 0) o.snapshot_lines = k.snapshotLines;
  if (k.imageUrls.length > 0) o.image_urls = k.imageUrls;
  return o;
}

export async function resolveStarterDeluxeSnapshots(
  supabase: import("@supabase/supabase-js").SupabaseClient,
  kits: ProductKitLine[],
): Promise<{ starter: string[]; deluxe: string[] }> {
  const { data: rows } = await supabase
    .from("kit_catalog_items")
    .select("id,label,sort_order")
    .order("sort_order", { ascending: true });

  const orderIdx = new Map<string, number>();
  const labelById = new Map<string, string>();
  for (const r of rows ?? []) {
    const rec = r as Record<string, unknown>;
    const id = rec.id == null ? "" : `${rec.id}`;
    if (!id) continue;
    orderIdx.set(
      id,
      typeof rec.sort_order === "number"
        ? rec.sort_order
        : Number.parseInt(`${rec.sort_order ?? 0}`, 10) || 0,
    );
    labelById.set(id, `${rec.label ?? ""}`.trim());
  }

  function linesForKit(k: ProductKitLine | undefined): string[] {
    if (!k) return [];
    if (!k.catalogIds.length) return [...k.snapshotLines];
    const ranked = [...k.catalogIds].sort(
      (a, b) => (orderIdx.get(a) ?? 99999) - (orderIdx.get(b) ?? 99999),
    );
    return ranked
      .map((id) => labelById.get(id))
      .filter((s): s is string => Boolean(s?.length));
  }

  const k0 = kits[0];
  const k1 = kits.length > 1 ? kits[1] : k0;
  return { starter: linesForKit(k0), deluxe: linesForKit(k1) };
}

/** Same columns as Flutter `Product.toInsertMap`. */
export function shopProductToInsertMap(
  p: ShopProduct,
  starterLabelSnapshot: string[],
  deluxeLabelSnapshot: string[],
  includeId: boolean,
): Record<string, unknown> {
  const k0 = p.kits[0];
  const k1 = p.kits.length > 1 ? p.kits[1] : k0;
  const k0Safe =
    k0 ??
    ({
      lineId: "placeholder",
      label: "Starter kit",
      catalogIds: [],
      priceInr: 0,
      presetId: null,
      snapshotLines: [],
      imageUrls: [],
    } as ProductKitLine);
  const k1Safe = k1 ?? k0Safe;

  const meta = (p.gallerySlideMeta ?? []).map((m) => ({
    flower_name: m.flowerName.trim(),
    ...(m.snippet != null && m.snippet.trim() !== ""
      ? { snippet: m.snippet.trim() }
      : {}),
  }));

  const row: Record<string, unknown> = {
    title: p.title.trim(),
    subtitle: p.subtitle.trim(),
    category: p.category,
    gallery_urls: p.galleryUrls,
    gallery_slide_meta: meta,
    cover_image_url: p.coverImageUrl.trim(),
    image_urls: p.galleryUrls,
    kits: (p.kits.length > 0 ? p.kits : [k0Safe]).map(kitLineToDbJson),
    price_starter_inr: k0Safe.priceInr ?? 0,
    price_deluxe_inr: k1Safe.priceInr ?? 0,
    starter_catalog_ids: k0Safe.catalogIds ?? [],
    deluxe_catalog_ids: k1Safe.catalogIds ?? [],
    items_starter: starterLabelSnapshot,
    items_deluxe: deluxeLabelSnapshot,
    in_stock: p.inStock,
    visible_in_shop: p.visibleInShop,
    highlight_tag_ids: p.highlightTagIds,
  };

  if (includeId && p.id.trim()) row.id = p.id.trim();
  return row;
}
