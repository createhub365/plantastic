/** Mirrors Flutter `kit_presets`. */

export type KitPreset = {
  id: string;
  name: string;
  catalogIds: string[];
  sortOrder: number;
};

export function parseKitPresetFromRow(
  row: Record<string, unknown>,
): KitPreset {
  const ord = row.sort_order;
  let catalogIds: string[] = [];
  const raw = row.catalog_ids;
  if (Array.isArray(raw)) {
    catalogIds = raw.map((e) => `${e}`.trim()).filter((s) => s.length > 0);
  }
  return {
    id: row.id == null ? "" : `${row.id}`,
    name: `${row.name ?? ""}`.trim(),
    catalogIds,
    sortOrder:
      typeof ord === "number"
        ? ord
        : Number.parseInt(`${ord ?? 0}`, 10) || 0,
  };
}
