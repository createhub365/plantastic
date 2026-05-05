/** Mirrors Flutter `highlight_tags` rows + seed catalogue. */

export type HighlightTag = {
  id: string;
  title: string;
  label: string;
  iconKey: string;
  body: string;
  sortOrder: number;
};

export function pillText(tag: HighlightTag): string {
  const l = tag.label.trim();
  if (l.length > 0) return l;
  const t = tag.title.trim();
  return t.length > 28 ? `${t.slice(0, 25)}…` : t;
}

const SEED_DEFS: readonly [
  id: string,
  title: string,
  label: string,
  iconKey: string,
  body: string,
  order: number,
][] = [
  [
    "00000000-0000-4000-8000-000000000001",
    "Eco-friendly growing",
    "Eco-friendly",
    "eco",
    "This plant carries the eco-friendly highlight because it suits a gentler grow routine.",
    10,
  ],
  [
    "00000000-0000-4000-8000-000000000002",
    "Pollinator-friendly blooms",
    "Pollinator friendly",
    "local_florist",
    "This plant is pollinator-friendly: its flowers invite bees and butterflies for nectar.",
    20,
  ],
  [
    "00000000-0000-4000-8000-000000000003",
    "Indoor air helpers",
    "Air purifying",
    "air",
    "This plant is air purifying: broad leaves help catch dust and balance room humidity.",
    30,
  ],
  [
    "00000000-0000-4000-8000-000000000004",
    "Freshness & green mood",
    "Oxygen & freshness",
    "oxygen",
    "This plant brings oxygen and freshness to your corner.",
    40,
  ],
  [
    "00000000-0000-4000-8000-000000000005",
    "Home & balcony ready",
    "Home friendly",
    "home",
    "This plant is home-friendly: compact habit and forgiving care make it slot into flats.",
    50,
  ],
  [
    "00000000-0000-4000-8000-000000000006",
    "Vastu-positive greens",
    "Vastu",
    "vastu",
    "This plant is chosen as vastu-positive green for the house.",
    60,
  ],
  [
    "00000000-0000-4000-8000-000000000007",
    "Forest-calming foliage",
    "Forest calm",
    "forest",
    "This plant carries forest-calm vibes: dense green foliage.",
    70,
  ],
  [
    "00000000-0000-4000-8000-000000000008",
    "Moderate watering",
    "Water wise",
    "water_drop",
    "This plant is water-wise: it rests well between drinks.",
    80,
  ],
  [
    "00000000-0000-4000-8000-000000000009",
    "Sun-loving varieties",
    "Sun lover",
    "wb_sunny",
    "This plant is sun-loving—reserve a sunny sill or railing for full effect.",
    90,
  ],
  [
    "00000000-0000-4000-8000-00000000000a",
    "Energising colour pops",
    "Energy",
    "energy",
    "This plant brings energising pops of colour.",
    100,
  ],
  [
    "00000000-0000-4000-8000-00000000000b",
    "Customer favourites",
    "Favourite picks",
    "favorite",
    "This plant is among customer favourites.",
    110,
  ],
  [
    "00000000-0000-4000-8000-00000000000c",
    "Wellness & mindful care",
    "Wellness",
    "health",
    "This plant supports wellness at home.",
    120,
  ],
  [
    "00000000-0000-4000-8000-00000000000d",
    "Less waste footprint",
    "Recycling wise",
    "recycling",
    "This product carries the recycling-wise note.",
    130,
  ],
  [
    "00000000-0000-4000-8000-00000000000e",
    "Compost-friendly growing",
    "Compost",
    "compost",
    "This plant fits compost-loving growers.",
    140,
  ],
];

export const seedHighlightCatalog: HighlightTag[] = SEED_DEFS.map(
  ([id, title, label, iconKey, body, order]) => ({
    id,
    title,
    label,
    iconKey,
    body,
    sortOrder: order,
  }),
);

export function parseHighlightTagFromRow(
  row: Record<string, unknown>,
): HighlightTag {
  const ord = row.sort_order;
  return {
    id: row.id == null ? "" : `${row.id}`,
    title: `${row.title ?? ""}`,
    label: `${row.label ?? ""}`,
    iconKey: `${row.icon_key ?? "eco"}`,
    body: `${row.body ?? ""}`,
    sortOrder:
      typeof ord === "number"
        ? ord
        : Number.parseInt(`${ord ?? 0}`, 10) || 0,
  };
}

export function highlightsForProduct(
  highlightTagIds: string[],
  catalog: HighlightTag[],
): HighlightTag[] {
  if (highlightTagIds.length === 0 || catalog.length === 0) return [];
  const byId = Object.fromEntries(catalog.map((h) => [h.id, h]));
  const out: HighlightTag[] = [];
  for (const id of highlightTagIds) {
    const h = byId[id.trim()];
    if (h) out.push(h);
  }
  return out;
}
