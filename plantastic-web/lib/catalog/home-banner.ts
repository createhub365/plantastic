import type {
  HomeBannerMediaKind,
  HomeBannerSlide,
  ShopHomeBanner,
} from "@/lib/catalog/types";

const FALLBACK: ShopHomeBanner = {
  mediaKind: "gradient",
  mediaUrl: null,
  titleOverlay: "Grow your own garden 🌱",
  slides: [],
  carouselIntervalMs: 5000,
  bannerHeightPx: 160,
  bannerMinHeightPx: 120,
  bannerMaxHeightPx: 280,
  glassBlur: true,
  glassSigma: 14,
  glassFillAlpha: 0.1,
  glassBorderAlpha: 0.28,
};

function readInt(v: unknown, fallback: number): number {
  if (v == null) return fallback;
  if (typeof v === "number" && Number.isFinite(v)) return Math.round(v);
  return Number.parseInt(`${v}`, 10) || fallback;
}

function readNum(v: unknown, fallback: number): number {
  if (v == null) return fallback;
  if (typeof v === "number" && Number.isFinite(v)) return v;
  const n = Number.parseFloat(`${v}`);
  return Number.isFinite(n) ? n : fallback;
}

function slideFromJson(m: Record<string, unknown>): HomeBannerSlide {
  const kindStr = `${m["kind"] ?? "image"}`.trim().toLowerCase();
  const kind: HomeBannerSlide["kind"] = kindStr === "video" ? "video" : "image";
  return {
    kind,
    url: `${m["url"] ?? ""}`.trim(),
    caption: `${m["caption"] ?? ""}`.trim(),
  };
}

export function homeBannerFallback(): ShopHomeBanner {
  return FALLBACK;
}

export function parseHomeBannerRow(
  row: Record<string, unknown> | null,
): ShopHomeBanner {
  if (!row) return FALLBACK;

  const rawKind = `${row["media_kind"] ?? "gradient"}`.trim().toLowerCase();
  let mediaKind: HomeBannerMediaKind = "gradient";
  if (rawKind === "image") mediaKind = "image";
  else if (rawKind === "video") mediaKind = "video";

  const urlRaw = row["media_url"];
  const trimmedUrl =
    urlRaw == null || `${urlRaw}`.trim() === "" ? null : `${urlRaw}`.trim();

  const titleRaw = row["title_overlay"];
  const title =
    titleRaw != null && `${titleRaw}`.trim() !== ""
      ? `${titleRaw}`.trim()
      : FALLBACK.titleOverlay;

  const slidesRaw = row["slides"];
  const slides: HomeBannerSlide[] = [];
  if (Array.isArray(slidesRaw)) {
    for (const e of slidesRaw) {
      if (e && typeof e === "object") {
        slides.push(slideFromJson(e as Record<string, unknown>));
      }
    }
  }

  const lo = readInt(row["banner_min_height_px"], 120);
  const hi = readInt(row["banner_max_height_px"], 280);
  const bh = readInt(row["banner_height_px"], 160);

  const glassBlur =
    typeof row["glass_blur"] === "boolean" ? row["glass_blur"] : true;

  return {
    mediaKind,
    mediaUrl: trimmedUrl,
    titleOverlay: title,
    slides,
    carouselIntervalMs: readInt(row["carousel_interval_ms"], 5000),
    bannerHeightPx: bh,
    bannerMinHeightPx: Math.min(lo, hi),
    bannerMaxHeightPx: Math.max(lo, hi),
    glassBlur,
    glassSigma: readNum(row["glass_sigma"], 14),
    glassFillAlpha: readNum(row["glass_fill_alpha"], 0.1),
    glassBorderAlpha: readNum(row["glass_border_alpha"], 0.28),
  };
}

/** Persist to `shop_home_banner` id=1 — matches Flutter `ShopHomeBannerConfig.toUpsertRow`. */
export function shopHomeBannerToUpsertRow(b: ShopHomeBanner): Record<string, unknown> {
  const lo = Math.min(b.bannerMinHeightPx, b.bannerMaxHeightPx);
  const hi = Math.max(b.bannerMinHeightPx, b.bannerMaxHeightPx);
  const bh = Math.min(Math.max(b.bannerHeightPx, lo), hi);
  const ci = Math.min(
    Math.max(b.carouselIntervalMs, 1500),
    60_000,
  );
  return {
    id: 1,
    media_kind: b.mediaKind,
    media_url: b.mediaUrl,
    title_overlay: b.titleOverlay.trim().length ? b.titleOverlay : FALLBACK.titleOverlay,
    slides: b.slides
      .filter((s) => s.url.trim().length > 0)
      .map((e) => ({
        kind: e.kind,
        url: e.url.trim(),
        caption: e.caption.trim(),
      })),
    carousel_interval_ms: ci,
    banner_height_px: bh,
    banner_min_height_px: lo,
    banner_max_height_px: hi,
    glass_blur: b.glassBlur,
    glass_sigma: Math.min(Math.max(b.glassSigma, 0), 40),
    glass_fill_alpha: Math.min(Math.max(b.glassFillAlpha, 0), 0.6),
    glass_border_alpha: Math.min(Math.max(b.glassBorderAlpha, 0), 0.8),
    updated_at: new Date().toISOString(),
  };
}

export function effectiveHeroSlides(config: ShopHomeBanner): HomeBannerSlide[] {
  const fromDb = config.slides.filter((s) => s.url.trim().length > 0);
  if (fromDb.length > 0) return fromDb;

  const url = config.mediaUrl?.trim();
  if (config.mediaKind === "gradient" || !url) return [];
  return [
    {
      kind: config.mediaKind === "video" ? "video" : "image",
      url,
      caption: config.titleOverlay,
    },
  ];
}

export function captionForSlide(
  config: ShopHomeBanner,
  slide: HomeBannerSlide,
): string {
  const c = slide.caption.trim();
  if (c.length > 0) return c;
  return config.titleOverlay.trim().length > 0
    ? config.titleOverlay
    : FALLBACK.titleOverlay;
}
