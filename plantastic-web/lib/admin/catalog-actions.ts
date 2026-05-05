"use server";

import { revalidatePath } from "next/cache";
import { requirePlantasticAdminSupabase } from "@/lib/admin/guard";
import {
  resolveStarterDeluxeSnapshots,
  shopProductToInsertMap,
} from "@/lib/admin/product-insert-map";
import type { ProductKitLine, ShopHomeBanner, ShopProduct } from "@/lib/catalog/types";
import {
  homeBannerFallback,
  shopHomeBannerToUpsertRow,
} from "@/lib/catalog/home-banner";
function actionErr(e: unknown): { error: string } {
  if (e instanceof Error) {
    if (e.message === "SIGN_IN_REQUIRED") return { error: "Please sign in." };
    if (e.message === "NOT_ADMIN") return { error: "Not authorized." };
    return { error: e.message };
  }
  return { error: "Request failed." };
}

export async function adminSetProductStock(
  id: string,
  inStock: boolean,
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase
      .from("products")
      .update({ in_stock: inStock })
      .eq("id", id);
    if (error) return { error: error.message };
    revalidatePath("/admin/products");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminSetProductVisible(
  id: string,
  visible: boolean,
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase
      .from("products")
      .update({ visible_in_shop: visible })
      .eq("id", id);
    if (error) return { error: error.message };
    revalidatePath("/admin/products");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminDeleteProducts(
  ids: string[],
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    for (const id of ids) {
      const { error } = await supabase.from("products").delete().eq("id", id);
      if (error) return { error: error.message };
    }
    revalidatePath("/admin/products");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

function validateKitLines(kits: unknown): ProductKitLine[] | null {
  if (!Array.isArray(kits) || kits.length === 0) return null;
  const out: ProductKitLine[] = [];
  for (const e of kits) {
    if (!e || typeof e !== "object") return null;
    const m = e as Record<string, unknown>;
    const lineId = m.lineId == null ? "" : `${m.lineId}`.trim();
    if (!lineId) return null;
    const label = `${m.label ?? "Kit"}`.trim();
    const priceRaw = m.priceInr;
    const priceInr =
      typeof priceRaw === "number"
        ? priceRaw
        : Number.parseInt(`${priceRaw ?? 0}`, 10) || 0;
    const catalogIds = readStrArray(m.catalogIds);
    const snapshotLines = readStrArray(m.snapshotLines);
    const imageUrls = readStrArray(m.imageUrls);
    const presetRaw = m.presetId;
    const presetId =
      presetRaw == null || `${presetRaw}`.trim() === ""
        ? null
        : `${presetRaw}`;
    out.push({
      lineId,
      label,
      catalogIds,
      priceInr,
      presetId,
      snapshotLines,
      imageUrls,
    });
  }
  return out;
}

function readStrArray(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.map((x) => `${x}`.trim()).filter((s) => s.length > 0);
}

export type AdminSaveProductPayload = {
  id?: string;
  title: string;
  subtitle: string;
  category: string;
  galleryUrls: string[];
  coverImageUrl: string;
  gallerySlideMeta?: { flowerName: string; snippet?: string }[];
  kits: unknown;
  highlightTagIds: string[];
  inStock: boolean;
  visibleInShop: boolean;
};

export async function adminSaveProductJson(
  json: string,
): Promise<{ ok?: true; error?: string; id?: string }> {
  let body: AdminSaveProductPayload;
  try {
    body = JSON.parse(json) as AdminSaveProductPayload;
  } catch {
    return { error: "Invalid product JSON." };
  }

  const kits = validateKitLines(body.kits);
  if (!kits) return { error: "Add at least one kit with line id, label, and price." };

  const galleryUrls =
    typeof body.galleryUrls === "undefined"
      ? []
      : Array.isArray(body.galleryUrls)
        ? body.galleryUrls.map((x) => `${x}`.trim()).filter(Boolean)
        : [];

  try {
    const supabase = await requirePlantasticAdminSupabase();

    const product: ShopProduct = {
      id: body.id?.trim() ?? "",
      title: `${body.title ?? ""}`.trim(),
      subtitle: `${body.subtitle ?? ""}`,
      category: `${body.category ?? ""}`.trim(),
      kits,
      galleryUrls,
      gallerySlideMeta: Array.isArray(body.gallerySlideMeta)
        ? body.gallerySlideMeta.map((m) => ({
            flowerName: `${m?.flowerName ?? ""}`.trim(),
            snippet:
              m?.snippet != null && `${m.snippet}`.trim() !== ""
                ? `${m.snippet}`.trim()
                : undefined,
          }))
        : [],
      coverImageUrl: `${body.coverImageUrl ?? ""}`.trim(),
      inStock: Boolean(body.inStock),
      visibleInShop: Boolean(body.visibleInShop),
      highlightTagIds: readUuidListFlexible(body.highlightTagIds),
    };

    if (!product.title) return { error: "Title is required." };
    if (!product.category) return { error: "Category is required." };

    const snaps = await resolveStarterDeluxeSnapshots(supabase, kits);

    const isUpdate = !!body.id?.trim();

    const row = shopProductToInsertMap(
      product,
      snaps.starter,
      snaps.deluxe,
      false,
    );

    if (!isUpdate) {
      delete row.id;
      const { data, error } = await supabase
        .from("products")
        .insert(row as never)
        .select("id")
        .single();

      if (error) return { error: error.message };
      const newId =
        data && typeof data === "object" && "id" in data
          ? `${(data as { id: unknown }).id}`
          : "";
      revalidatePath("/admin/products");
      revalidatePath("/");
      return { ok: true, id: newId };
    }

    const { error } = await supabase
      .from("products")
      .update(row as never)
      .eq("id", product.id);
    if (error) return { error: error.message };

    revalidatePath("/admin/products");
    revalidatePath(`/admin/products/${product.id}/edit`);
    revalidatePath("/");
    revalidatePath(`/products/${product.id}`);
    return { ok: true, id: product.id };
  } catch (e) {
    return actionErr(e);
  }
}

function readUuidListFlexible(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.map((x) => `${x}`.trim()).filter((s) => s.length > 0);
}

export async function adminUpdateOrderStatus(
  orderId: string,
  status: string,
): Promise<{ ok?: true; error?: string }> {
  const canon = `${status}`.trim().toLowerCase();
  const choices = ["pending", "shipped", "delivered"];
  const s = choices.includes(canon) ? canon : "pending";
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase.from("orders").update({ status: s }).eq("id", orderId);
    if (error) return { error: error.message };
    revalidatePath("/admin/orders");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminCreateKitCatalogItem(
  label: string,
): Promise<{ ok?: true; error?: string; id?: string }> {
  const t = label.trim();
  if (t.length < 1) return { error: "Label required." };
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { data: rows } = await supabase
      .from("kit_catalog_items")
      .select("sort_order")
      .order("sort_order", { ascending: false })
      .limit(1);
    const maxOrd =
      rows?.[0] && typeof rows[0] === "object" && "sort_order" in rows[0]
        ? Number((rows[0] as { sort_order: unknown }).sort_order)
        : 0;
    const sortOrder = (Number.isFinite(maxOrd) ? maxOrd : 0) + 10;

    const { data, error } = await supabase
      .from("kit_catalog_items")
      .insert({ label: t, sort_order: sortOrder } as never)
      .select("id")
      .single();
    if (error) return { error: error.message };
    const id = data && typeof data === "object" && "id" in data ? `${(data as { id: unknown }).id}` : "";
    revalidatePath("/admin/kit-items");
    return { ok: true, id };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminUpdateKitCatalogLabel(
  id: string,
  label: string,
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase
      .from("kit_catalog_items")
      .update({ label: label.trim() })
      .eq("id", id);
    if (error) return { error: error.message };
    revalidatePath("/admin/kit-items");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminDeleteKitCatalogItem(
  id: string,
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase.from("kit_catalog_items").delete().eq("id", id);
    if (error) return { error: error.message };
    revalidatePath("/admin/kit-items");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminReorderKitCatalog(
  orderedIds: string[],
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    for (let i = 0; i < orderedIds.length; i++) {
      const { error } = await supabase
        .from("kit_catalog_items")
        .update({ sort_order: (i + 1) * 10 })
        .eq("id", orderedIds[i]!);
      if (error) return { error: error.message };
    }
    revalidatePath("/admin/kit-items");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminCreateKitPreset(payload: {
  name: string;
  catalogIds: string[];
  sortOrder?: number;
}): Promise<{ ok?: true; error?: string; id?: string }> {
  const name = payload.name.trim();
  if (!name) return { error: "Name required." };
  const catalogIds =
    typeof payload.catalogIds === "undefined" ? [] : readUuidListFlexible(payload.catalogIds);
  try {
    const supabase = await requirePlantasticAdminSupabase();
    let sortOrder = payload.sortOrder;
    if (sortOrder == null) {
      const { data: rows } = await supabase
        .from("kit_presets")
        .select("sort_order")
        .order("sort_order", { ascending: false })
        .limit(1);
      const maxOrd =
        rows?.[0] && typeof rows[0] === "object" && "sort_order" in rows[0]
          ? Number((rows[0] as { sort_order: unknown }).sort_order)
          : 0;
      sortOrder = (Number.isFinite(maxOrd) ? maxOrd : 0) + 10;
    }

    const { data, error } = await supabase
      .from("kit_presets")
      .insert({
        name,
        catalog_ids: catalogIds,
        sort_order: sortOrder ?? 10,
      } as never)
      .select("id")
      .single();

    if (error) return { error: error.message };
    const id =
      data && typeof data === "object" && "id" in data ? `${(data as { id: unknown }).id}` : "";
    revalidatePath("/admin/kit-presets");
    return { ok: true, id };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminUpdateKitPreset(payload: {
  id: string;
  name: string;
  catalogIds: string[];
  sortOrder: number;
}): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase
      .from("kit_presets")
      .update({
        name: payload.name.trim(),
        catalog_ids: readUuidListFlexible(payload.catalogIds),
        sort_order: payload.sortOrder,
      })
      .eq("id", payload.id);
    if (error) return { error: error.message };
    revalidatePath("/admin/kit-presets");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminDeleteKitPreset(id: string): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase.from("kit_presets").delete().eq("id", id);
    if (error) return { error: error.message };
    revalidatePath("/admin/kit-presets");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminReorderKitPresets(
  orderedIds: string[],
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    for (let i = 0; i < orderedIds.length; i++) {
      const { error } = await supabase
        .from("kit_presets")
        .update({ sort_order: (i + 1) * 10 })
        .eq("id", orderedIds[i]!);
      if (error) return { error: error.message };
    }
    revalidatePath("/admin/kit-presets");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminCreateHighlight(payload: {
  title: string;
  label?: string;
  iconKey?: string;
  body?: string;
  sortOrder?: number;
}): Promise<{ ok?: true; error?: string }> {
  const title = payload.title.trim();
  if (title.length < 2) return { error: "Title needs at least 2 characters." };
  try {
    const supabase = await requirePlantasticAdminSupabase();
    let sortOrder = payload.sortOrder;
    if (sortOrder == null) {
      const { data: rows } = await supabase
        .from("highlight_tags")
        .select("sort_order")
        .order("sort_order", { ascending: false })
        .limit(1);
      const maxOrd =
        rows?.[0] && typeof rows[0] === "object" && "sort_order" in rows[0]
          ? Number((rows[0] as { sort_order: unknown }).sort_order)
          : 0;
      sortOrder = (Number.isFinite(maxOrd) ? maxOrd : 0) + 10;
    }

    const { error } = await supabase.from("highlight_tags").insert({
      title,
      label: `${payload.label ?? ""}`.trim(),
      icon_key: `${payload.iconKey ?? "eco"}`.trim(),
      body: `${payload.body ?? ""}`,
      sort_order: sortOrder ?? 10,
    } as never);

    if (error) return { error: error.message };
    revalidatePath("/admin/highlights");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminUpdateHighlight(payload: {
  id: string;
  title: string;
  label: string;
  iconKey: string;
  body: string;
}): Promise<{ ok?: true; error?: string }> {
  const title = payload.title.trim();
  if (title.length < 2) return { error: "Title needs at least 2 characters." };
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase
      .from("highlight_tags")
      .update({
        title,
        label: payload.label.trim(),
        icon_key: payload.iconKey.trim(),
        body: payload.body,
      })
      .eq("id", payload.id);
    if (error) return { error: error.message };
    revalidatePath("/admin/highlights");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminDeleteHighlight(id: string): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const { error } = await supabase.from("highlight_tags").delete().eq("id", id);
    if (error) return { error: error.message };
    revalidatePath("/admin/highlights");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminReorderHighlights(
  orderedIds: string[],
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    for (let i = 0; i < orderedIds.length; i++) {
      const { error } = await supabase
        .from("highlight_tags")
        .update({ sort_order: (i + 1) * 10 })
        .eq("id", orderedIds[i]!);
      if (error) return { error: error.message };
    }
    revalidatePath("/admin/highlights");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminSaveHomeBannerJson(
  json: string,
): Promise<{ ok?: true; error?: string }> {
  let b: ShopHomeBanner;
  try {
    b = JSON.parse(json) as ShopHomeBanner;
  } catch {
    return { error: "Invalid banner JSON." };
  }
  const slides = Array.isArray(b.slides) ? b.slides : [];
  if (!slides.some((s) => s.url.trim().length > 0)) {
    return { error: "Add at least one slide URL (or use gradient reset)." };
  }
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const normalized: ShopHomeBanner = {
      ...homeBannerFallback(),
      ...b,
      mediaKind: "gradient",
      mediaUrl: null,
      slides: slides.filter((s) => s.url.trim().length > 0),
    };
    const { error } = await supabase
      .from("shop_home_banner")
      .upsert(shopHomeBannerToUpsertRow(normalized) as never, { onConflict: "id" });
    if (error) return { error: error.message };
    revalidatePath("/admin/home-banner");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}

export async function adminResetHomeBannerGradient(
  titleOverlay: string,
): Promise<{ ok?: true; error?: string }> {
  try {
    const supabase = await requirePlantasticAdminSupabase();
    const base = homeBannerFallback();
    const overlay =
      titleOverlay.trim().length > 0 ? titleOverlay.trim() : base.titleOverlay;
    const cfg: ShopHomeBanner = {
      ...base,
      mediaKind: "gradient",
      mediaUrl: null,
      titleOverlay: overlay,
      slides: [],
    };
    const { error } = await supabase
      .from("shop_home_banner")
      .upsert(shopHomeBannerToUpsertRow(cfg) as never, { onConflict: "id" });
    if (error) return { error: error.message };
    revalidatePath("/admin/home-banner");
    revalidatePath("/");
    return { ok: true };
  } catch (e) {
    return actionErr(e);
  }
}
