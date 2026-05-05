import {
  CATEGORY_FLOWER_SEED,
  CATEGORY_PLANT_SEED,
} from "@/lib/catalog/constants";
import type { ProductKitLine, ShopProduct } from "@/lib/catalog/types";

function kitsForSeed(pid: string): ProductKitLine[] {
  return [
    {
      lineId: `${pid}__stk`,
      label: "Starter kit",
      catalogIds: [],
      priceInr: 499,
      presetId: null,
      snapshotLines: [],
      imageUrls: [],
    },
    {
      lineId: `${pid}__dlx`,
      label: "Deluxe kit",
      catalogIds: [],
      priceInr: 799,
      presetId: null,
      snapshotLines: [],
      imageUrls: [],
    },
  ];
}

/** Seed catalogue when Supabase is off or empty — matches Flutter `seed_products.dart`. */
export const seedProducts: ShopProduct[] = [
  {
    id: "marigold-orange",
    title: "Marigold Orange",
    subtitle:
      "Vivid orange blooms on sturdy, sun-loving plants—great for railing pots, edging beds, and cheerful patio colour all season.",
    category: CATEGORY_FLOWER_SEED,
    kits: kitsForSeed("marigold-orange"),
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  },
  {
    id: "sunfolk-sunflower",
    title: "Sunflower Dwarf",
    subtitle:
      "Compact sunflower varieties with sunny faces sized for pots and small gardens—welcomes pollinators without towering growth.",
    category: CATEGORY_FLOWER_SEED,
    kits: kitsForSeed("sunfolk-sunflower"),
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  },
  {
    id: "petunia-mix",
    title: "Petunia Cascade Mix",
    subtitle:
      "Trailing mixed petunias for hanging baskets and window boxes—soft pastels and bright tones that spill richly over edges.",
    category: CATEGORY_FLOWER_SEED,
    kits: kitsForSeed("petunia-mix"),
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  },
  {
    id: "zinnia-bright",
    title: "Zinnia Cutting Mix",
    subtitle:
      "A cutting-friendly zinnia blend with long stems and bold colour—loves full heat and sun; cut often for bouquets and repeat blooms.",
    category: CATEGORY_FLOWER_SEED,
    kits: kitsForSeed("zinnia-bright"),
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  },
  {
    id: "tomato-cherry-balcony",
    title: "Cherry Tomato Patio",
    subtitle:
      "Dwarf cherry tomato types for balconies and patios—sweet bite-sized fruit from manageable vines in grow bags or sunny pots.",
    category: CATEGORY_PLANT_SEED,
    kits: kitsForSeed("tomato-cherry-balcony"),
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  },
  {
    id: "basil-genovese",
    title: "Basil Genovese",
    subtitle:
      "Sweet Genovese basil seed—large fragrant leaves for pesto, salads, and summer cooking; pinch growing tips for a bushy herb pot.",
    category: CATEGORY_PLANT_SEED,
    kits: kitsForSeed("basil-genovese"),
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  },
];
