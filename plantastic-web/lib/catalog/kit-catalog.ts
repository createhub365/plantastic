/** Mirrors Flutter `kit_catalog_items` + `KitCatalogIds` fallbacks. */

export type KitCatalogItem = {
  id: string;
  label: string;
  sortOrder: number;
};

export const seedPacket = "11111111-1111-4111-a111-000000000101";
export const soilMix = "11111111-1111-4111-a111-000000000102";
export const compostItem = "11111111-1111-4111-a111-000000000103";
export const coconutCoir = "11111111-1111-4111-a111-000000000104";
export const towel = "11111111-1111-4111-a111-000000000201";
export const gloves = "11111111-1111-4111-a111-000000000202";
export const scoop = "11111111-1111-4111-a111-000000000203";

/** Offline labels when catalogue row missing (Flutter `KitCatalogIds.defaultLabelsById`). */
export const defaultLabelsById: Record<string, string> = {
  [seedPacket]: "Selected seed packet",
  [soilMix]: "Garden soil mix",
  [compostItem]: "Organic compost",
  [coconutCoir]: "Coconut coir",
  [towel]: "Hand towel",
  [gloves]: "Gardening gloves",
  [scoop]: "Soil scoop",
};

export function seededKitCatalogInOrder(): KitCatalogItem[] {
  return [
    { id: seedPacket, label: defaultLabelsById[seedPacket]!, sortOrder: 10 },
    { id: soilMix, label: defaultLabelsById[soilMix]!, sortOrder: 20 },
    { id: compostItem, label: defaultLabelsById[compostItem]!, sortOrder: 30 },
    { id: coconutCoir, label: defaultLabelsById[coconutCoir]!, sortOrder: 40 },
    { id: towel, label: defaultLabelsById[towel]!, sortOrder: 50 },
    { id: gloves, label: defaultLabelsById[gloves]!, sortOrder: 60 },
    { id: scoop, label: defaultLabelsById[scoop]!, sortOrder: 70 },
  ];
}

export function parseKitCatalogItemFromRow(
  row: Record<string, unknown>,
): KitCatalogItem {
  const ord = row.sort_order;
  return {
    id: row.id == null ? "" : `${row.id}`,
    label: `${row.label ?? ""}`,
    sortOrder:
      typeof ord === "number"
        ? ord
        : Number.parseInt(`${ord ?? 0}`, 10) || 0,
  };
}
