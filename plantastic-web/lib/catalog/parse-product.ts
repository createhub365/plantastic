import type {
  GallerySlideMeta,
  ProductKitLine,
  ShopProduct,
} from "@/lib/catalog/types";

function readStringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((e) => `${e}`.trim())
    .filter((s) => s.length > 0);
}

function readUuidList(raw: unknown): string[] {
  return readStringList(raw);
}

function readUrlsFromMap(map: Record<string, unknown>): string[] {
  const prim = map["gallery_urls"];
  if (Array.isArray(prim) && prim.length > 0) {
    return readStringList(prim);
  }
  const fallback = map["image_urls"];
  if (Array.isArray(fallback) && fallback.length > 0) {
    return readStringList(fallback);
  }
  return [];
}

function readGallerySlideMeta(raw: unknown): GallerySlideMeta[] {
  if (!Array.isArray(raw)) return [];
  const out: GallerySlideMeta[] = [];
  for (const e of raw) {
    if (!e || typeof e !== "object") continue;
    const m = e as Record<string, unknown>;
    const flowerRaw = m.flower_name ?? m.flowerName;
    const snippetRaw = m.snippet ?? "";
    out.push({
      flowerName: flowerRaw == null ? "" : `${flowerRaw}`.trim(),
      snippet: snippetRaw == null ? undefined : `${snippetRaw}`.trim(),
    });
  }
  return out;
}

function kitLineFromMap(m: Record<string, unknown>): ProductKitLine | null {
  const lid = m["line_id"];
  const lineId = lid == null ? "" : `${lid}`.trim();
  const priceRaw = m["price_inr"];
  const priceInr =
    typeof priceRaw === "number"
      ? priceRaw
      : Number.parseInt(`${priceRaw ?? 0}`, 10) || 0;
  const presetRaw = m["preset_id"];
  const presetId =
    presetRaw == null || `${presetRaw}`.trim() === ""
      ? null
      : `${presetRaw}`;

  return {
    lineId,
    label: `${m["label"] ?? "Kit"}`.trim(),
    presetId,
    catalogIds: readUuidList(m["catalog_ids"]),
    priceInr,
    snapshotLines: readStringList(m["snapshot_lines"]),
    imageUrls: readUuidList(m["image_urls"]),
  };
}

function kitsFromPayload(map: Record<string, unknown>): ProductKitLine[] {
  const raw = map["kits"];
  if (!Array.isArray(raw) || raw.length === 0) {
    return kitsFromLegacyColumns(map);
  }

  const out: ProductKitLine[] = [];
  for (const e of raw) {
    if (!e || typeof e !== "object") continue;
    const k = kitLineFromMap(e as Record<string, unknown>);
    if (k && k.lineId.length > 0) out.push(k);
  }
  if (out.length > 0) return out;

  return kitsFromLegacyColumns(map);
}

function kitsFromLegacyColumns(map: Record<string, unknown>): ProductKitLine[] {
  const idRaw = map["id"];
  const pid = idRaw == null ? "p" : `${idRaw}`;
  const ps = map["price_starter_inr"];
  const pd = map["price_deluxe_inr"];
  const priceS =
    typeof ps === "number" ? ps : Number.parseInt(`${ps ?? 499}`, 10) || 499;
  const priceD =
    typeof pd === "number" ? pd : Number.parseInt(`${pd ?? 799}`, 10) || 799;

  const starterIds = readUuidList(map["starter_catalog_ids"]);
  const deluxeIds = readUuidList(map["deluxe_catalog_ids"]);
  const itemsStarter =
    starterIds.length === 0 ? readStringList(map["items_starter"]) : [];
  const itemsDeluxe =
    deluxeIds.length === 0 ? readStringList(map["items_deluxe"]) : [];

  return [
    {
      lineId: `${pid}_starter`,
      label: "Starter kit",
      catalogIds: starterIds,
      priceInr: priceS,
      snapshotLines: itemsStarter,
      imageUrls: [],
    },
    {
      lineId: `${pid}_deluxe`,
      label: "Deluxe kit",
      catalogIds: deluxeIds,
      priceInr: priceD,
      snapshotLines: itemsDeluxe,
      imageUrls: [],
    },
  ];
}

function looksLikeUsableShopRemoteUrl(c: string): boolean {
  return /^https?:\/\//i.test(c.trim());
}

export function effectiveNetworkCoverUrl(p: ShopProduct): string | null {
  const c = p.coverImageUrl.trim();
  if (looksLikeUsableShopRemoteUrl(c)) return c;
  for (const u of p.galleryUrls) {
    if (looksLikeUsableShopRemoteUrl(u)) return u;
  }
  return null;
}

export function lowestKitPriceInr(p: ShopProduct): number {
  if (p.kits.length === 0) return 0;
  let m = p.kits[0].priceInr;
  for (let i = 1; i < p.kits.length; i++) {
    const q = p.kits[i].priceInr;
    if (q < m) m = q;
  }
  return m;
}

/** Subtitle for UI/metadata only when it adds something beyond repeating the title. */
export function distinctProductSubtitle(product: {
  title: string;
  subtitle: string;
}): string | null {
  const sub = product.subtitle.trim();
  if (!sub) return null;
  const t = product.title.trim();
  if (t.length > 0 && sub.toLowerCase() === t.toLowerCase()) return null;
  return sub;
}

export function productFromRow(row: Record<string, unknown>): ShopProduct {
  const kits = kitsFromPayload(row);
  return {
    id: row["id"] == null ? "" : `${row["id"]}`,
    title: `${row["title"] ?? ""}`,
    subtitle: `${row["subtitle"] ?? ""}`,
    category: `${row["category"] ?? ""}`,
    kits,
    galleryUrls: readUrlsFromMap(row),
    gallerySlideMeta: readGallerySlideMeta(row["gallery_slide_meta"]),
    coverImageUrl: `${row["cover_image_url"] ?? ""}`.trim(),
    inStock:
      typeof row["in_stock"] === "boolean"
        ? (row["in_stock"] as boolean)
        : true,
    visibleInShop:
      typeof row["visible_in_shop"] === "boolean"
        ? (row["visible_in_shop"] as boolean)
        : true,
    highlightTagIds: readUuidList(row["highlight_tag_ids"]),
  };
}