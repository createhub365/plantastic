import type { ProductKitLine } from "@/lib/catalog/types";
import {
  defaultLabelsById,
  type KitCatalogItem,
} from "@/lib/catalog/kit-catalog";

export type KitInclusionEntry = { catalogId: string; label: string };

/** Same rules as Flutter `ProductKitLine.inclusionEntries`. */
export function inclusionEntriesForKit(
  kit: ProductKitLine,
  catalog: KitCatalogItem[] | null | undefined,
): KitInclusionEntry[] {
  const catalogRows = catalog ?? [];
  const catalogIds = kit.catalogIds ?? [];
  const idsToUse =
    catalogIds.length > 0 ? [...catalogIds] : ([] as string[]);

  if (idsToUse.length === 0) {
    const snaps = (kit.snapshotLines ?? [])
      .map((s) => s.trim())
      .filter(Boolean);
    return snaps.map((label) => ({ catalogId: "", label }));
  }

  const orderIdx: Record<string, number> = {};
  for (const c of catalogRows) {
    orderIdx[c.id] = c.sortOrder;
  }

  const byId: Record<string, string> = { ...defaultLabelsById };
  for (const c of catalogRows) {
    const t = c.label.trim();
    if (t.length > 0) byId[c.id] = t;
  }

  const ranked = [...idsToUse].sort(
    (a, b) => (orderIdx[a] ?? 99999) - (orderIdx[b] ?? 99999),
  );

  const out: KitInclusionEntry[] = [];
  for (const id of ranked) {
    const label = (byId[id] ?? "").trim();
    if (label.length > 0) out.push({ catalogId: id, label });
  }
  return out;
}

export function inclusionLinesForKit(
  kit: ProductKitLine,
  catalog: KitCatalogItem[] | null | undefined,
): string[] {
  return inclusionEntriesForKit(kit, catalog).map((e) => e.label);
}
