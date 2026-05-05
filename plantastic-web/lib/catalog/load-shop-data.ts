import { cache } from "react";
import { productFromRow } from "@/lib/catalog/parse-product";
import { seedProducts } from "@/lib/catalog/seed-products";
import type { ShopHomeBanner, ShopProduct } from "@/lib/catalog/types";
import {
  homeBannerFallback,
  parseHomeBannerRow,
} from "@/lib/catalog/home-banner";
import {
  getSupabasePublicConfig,
  restSelect,
  restSelectSingle,
} from "@/lib/supabase/rest";
import {
  parseHighlightTagFromRow,
  seedHighlightCatalog,
  type HighlightTag,
} from "@/lib/catalog/highlight-tags";
import {
  parseKitCatalogItemFromRow,
  seededKitCatalogInOrder,
  type KitCatalogItem,
} from "@/lib/catalog/kit-catalog";

export async function loadShopProducts(): Promise<ShopProduct[]> {
  if (!getSupabasePublicConfig()) {
    return seedProducts;
  }

  const { data, error } = await restSelect<Record<string, unknown>>(
    "products",
    "select=*&order=created_at.desc",
  );
  if (!data || error) {
    return seedProducts;
  }

  const parsed = data
    .map((row) => productFromRow(row))
    .filter((p) => p.id.trim().length > 0);
  return parsed.length > 0 ? parsed : seedProducts;
}

export async function loadShopHomeBanner(): Promise<ShopHomeBanner> {
  if (!getSupabasePublicConfig()) {
    return homeBannerFallback();
  }

  const { data, error } = await restSelectSingle<Record<string, unknown>>(
    "shop_home_banner",
    "select=*&id=eq.1",
  );
  if (!data || error) {
    return homeBannerFallback();
  }
  return parseHomeBannerRow(data);
}

export async function loadProductById(
  id: string,
): Promise<ShopProduct | null> {
  const decoded = decodeURIComponent(id.trim());
  if (!decoded) return null;

  if (!getSupabasePublicConfig()) {
    return seedProducts.find((p) => p.id === decoded) ?? null;
  }

  const { data, error } = await restSelectSingle<Record<string, unknown>>(
    "products",
    `select=*&id=eq.${encodeURIComponent(decoded)}`,
  );
  if (!error && data) {
    const parsed = productFromRow(data);
    if (parsed.id.trim().length > 0) return parsed;
  }

  return seedProducts.find((p) => p.id === decoded) ?? null;
}

export const loadHighlightCatalog = cache(
  async (): Promise<HighlightTag[]> => {
    if (!getSupabasePublicConfig()) {
      return seedHighlightCatalog;
    }

    const { data, error } = await restSelect<Record<string, unknown>>(
      "highlight_tags",
      "select=*&order=sort_order.asc",
    );
    if (!data || error) {
      return seedHighlightCatalog;
    }

    const parsed = data
      .map((row) => parseHighlightTagFromRow(row))
      .filter((h) => h.id.trim());
    return parsed.length > 0 ? parsed : seedHighlightCatalog;
  },
);

export const loadKitCatalog = cache(async (): Promise<KitCatalogItem[]> => {
  if (!getSupabasePublicConfig()) {
    return seededKitCatalogInOrder();
  }

  const { data, error } = await restSelect<Record<string, unknown>>(
    "kit_catalog_items",
    "select=*&order=sort_order.asc",
  );
  if (!data || error) {
    return seededKitCatalogInOrder();
  }

  const parsed = data
    .map((row) => parseKitCatalogItemFromRow(row))
    .filter((k) => k.id.trim());

  const sorted =
    parsed.length > 0
      ? [...parsed].sort((a, b) => a.sortOrder - b.sortOrder)
      : seededKitCatalogInOrder();

  return sorted.length > 0 ? sorted : seededKitCatalogInOrder();
});
