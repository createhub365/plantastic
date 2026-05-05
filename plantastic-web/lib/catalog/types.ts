export type ProductKitLine = {
  lineId: string;
  label: string;
  catalogIds: string[];
  priceInr: number;
  presetId?: string | null;
  snapshotLines: string[];
  imageUrls: string[];
};

export type GallerySlideMeta = {
  flowerName: string;
  snippet?: string;
};

export type ShopProduct = {
  id: string;
  title: string;
  subtitle: string;
  category: string;
  kits: ProductKitLine[];
  galleryUrls: string[];
  gallerySlideMeta: GallerySlideMeta[];
  coverImageUrl: string;
  inStock: boolean;
  visibleInShop: boolean;
  highlightTagIds: string[];
};

export type HomeBannerMediaKind = "gradient" | "image" | "video";

export type HomeBannerSlide = {
  kind: "image" | "video";
  url: string;
  caption: string;
};

export type ShopHomeBanner = {
  mediaKind: HomeBannerMediaKind;
  mediaUrl: string | null;
  titleOverlay: string;
  slides: HomeBannerSlide[];
  carouselIntervalMs: number;
  bannerHeightPx: number;
  bannerMinHeightPx: number;
  bannerMaxHeightPx: number;
  glassBlur: boolean;
  glassSigma: number;
  glassFillAlpha: number;
  glassBorderAlpha: number;
};
