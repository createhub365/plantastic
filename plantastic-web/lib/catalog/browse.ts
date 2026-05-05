import {
  CATEGORY_FLOWER_SEED,
  CATEGORY_PLANT_SEED,
  HIGHLIGHT_FAVOURITE_PICKS,
} from "@/lib/catalog/constants";
import type { ShopProduct } from "@/lib/catalog/types";
import { effectiveNetworkCoverUrl } from "@/lib/catalog/parse-product";

export type HomeBrowseTab = "flowers" | "plants" | "starterKits" | "bestSellers";

function scoreForSort(p: ShopProduct): number {
  const net = Boolean(effectiveNetworkCoverUrl(p)?.trim());
  let s = net ? 4 : 0;
  const path =
    `${p.coverImageUrl ?? ""}${(p.galleryUrls ?? []).join(" ")}`.toLowerCase();
  if (path.includes("logo")) s -= 3;
  const t = p.title.toLowerCase();
  if (t.includes("plantastic") && t.length < 24) s -= 2;
  return s;
}

function preferLikelyPhotoFirst(products: ShopProduct[]): ShopProduct[] {
  if (products.length <= 1) return products;
  return [...products].sort((a, b) => scoreForSort(b) - scoreForSort(a));
}

export function visibleForBrowse(
  shop: Iterable<ShopProduct>,
  kind: HomeBrowseTab,
): ShopProduct[] {
  const shopList = [...shop];
  switch (kind) {
    case "flowers":
      return preferLikelyPhotoFirst(
        shopList.filter((p) => p.category === CATEGORY_FLOWER_SEED),
      );
    case "plants":
      return preferLikelyPhotoFirst(
        shopList.filter((p) => p.category === CATEGORY_PLANT_SEED),
      );
    case "starterKits":
      return preferLikelyPhotoFirst(
        shopList.filter((p) =>
          p.kits.some(
            (kit) =>
              kit.lineId.endsWith("__stk") ||
              kit.label.toLowerCase().includes("starter"),
          ),
        ),
      );
    case "bestSellers": {
      const tagged = preferLikelyPhotoFirst(
        shopList.filter((p) =>
          p.highlightTagIds.includes(HIGHLIGHT_FAVOURITE_PICKS),
        ),
      );
      if (tagged.length > 0) return tagged;
      const fallback = shopList.slice(0, 4);
      return preferLikelyPhotoFirst(
        fallback.length > 0 ? fallback : shopList,
      );
    }
    default:
      return preferLikelyPhotoFirst(shopList);
  }
}
