import { CATEGORY_FLOWER_SEED } from "@/lib/catalog/constants";
import type { ShopProduct } from "@/lib/catalog/types";

export function makeEmptyDraftProduct(): ShopProduct {
  const a = crypto.randomUUID();
  const b = crypto.randomUUID();
  return {
    id: "",
    title: "",
    subtitle: "",
    category: CATEGORY_FLOWER_SEED,
    kits: [
      {
        lineId: `k_${a}`,
        label: "Starter kit",
        catalogIds: [],
        priceInr: 499,
        presetId: null,
        snapshotLines: [],
        imageUrls: [],
      },
      {
        lineId: `k_${b}`,
        label: "Deluxe kit",
        catalogIds: [],
        priceInr: 799,
        presetId: null,
        snapshotLines: [],
        imageUrls: [],
      },
    ],
    galleryUrls: [],
    gallerySlideMeta: [],
    coverImageUrl: "",
    inStock: true,
    visibleInShop: true,
    highlightTagIds: [],
  };
}
