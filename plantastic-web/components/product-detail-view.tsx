"use client";

import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  AnimatePresence,
  LayoutGroup,
  motion,
  useReducedMotion,
} from "framer-motion";
import {
  startTransition,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import gsap from "gsap";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import { highlightsForProduct } from "@/lib/catalog/highlight-tags";
import { inclusionEntriesForKit } from "@/lib/catalog/inclusions";
import type { KitCatalogItem } from "@/lib/catalog/kit-catalog";
import {
  distinctProductSubtitle,
  effectiveNetworkCoverUrl,
} from "@/lib/catalog/parse-product";
import type { ShopProduct } from "@/lib/catalog/types";
import { CategoryPill, HighlightChipsRow } from "@/components/category-highlight-ui";
import { HighlightDetailModal } from "@/components/highlight-detail-modal";
import { InclusionListGsap } from "@/components/inclusion-list-gsap";
import { PhosphorIcon } from "@/components/phosphor-icon";
import { useCart } from "@/lib/cart/cart-context";
import { fadeUp } from "@/lib/motion/variants";
import { colors } from "@/lib/theme/colors";
import { ArrowLeft } from "@phosphor-icons/react/dist/csr/ArrowLeft";

/** Auto-advance main gallery on product detail when multiple images exist. */
const PRODUCT_GALLERY_AUTO_MS = 5000;

function remoteGalleryUrls(product: ShopProduct): string[] {
  const out: string[] = [];
  const cover = effectiveNetworkCoverUrl(product);
  if (cover) out.push(cover);
  for (const u of product.galleryUrls) {
    const t = u.trim();
    if (!/^https?:\/\//i.test(t)) continue;
    if (out.includes(t)) continue;
    out.push(t);
  }
  return out;
}

export function ProductDetailView({
  product,
  highlightCatalog,
  kitCatalog,
}: {
  product: ShopProduct;
  highlightCatalog: HighlightTag[];
  kitCatalog: KitCatalogItem[];
}) {
  const reduceMotion = useReducedMotion();
  const cart = useCart();
  const router = useRouter();
  const images = useMemo(() => remoteGalleryUrls(product), [product]);
  const [imgIndex, setImgIndex] = useState(0);
  /** Pause auto-slide while pointer is over the gallery (thumbs + hero). */
  const [galleryHoverPause, setGalleryHoverPause] = useState(false);
  const [modalTag, setModalTag] = useState<HighlightTag | null>(null);
  const heroPanelRef = useRef<HTMLDivElement>(null);

  const kits = product.kits;
  const defaultLineId = kits[0]?.lineId ?? "";
  const [lineId, setLineId] = useState(defaultLineId);

  useEffect(() => {
    startTransition(() => {
      setLineId(product.kits[0]?.lineId ?? "");
      setImgIndex(0);
    });
    // Kits read from latest `product` when navigating to another product (`product.id`).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [product.id]);

  useEffect(() => {
    if (reduceMotion || images.length <= 1 || galleryHoverPause) return;

    const ms = Math.min(60_000, Math.max(2500, PRODUCT_GALLERY_AUTO_MS));
    const id = window.setInterval(() => {
      if (document.visibilityState !== "visible") return;
      setImgIndex((i) => (i + 1) % images.length);
    }, ms);

    return () => window.clearInterval(id);
  }, [
    galleryHoverPause,
    images.length,
    product.id,
    reduceMotion,
  ]);

  const selected =
    kits.find((k) => k.lineId === lineId) ?? kits[0] ?? null;

  const available = product.inStock && product.visibleInShop;
  const lineHighlights = highlightsForProduct(
    product.highlightTagIds,
    highlightCatalog,
  );

  const inclusionEntries = useMemo(() => {
    if (!selected) return [];
    return inclusionEntriesForKit(selected, kitCatalog ?? []);
  }, [selected, kitCatalog]);

  const inclusionAnimKey =
    `${selected?.lineId ?? ""}:${inclusionEntries.map((e) => e.label).join("|")}`;

  const subtitleLine = useMemo(
    () => distinctProductSubtitle(product),
    [product.title, product.subtitle],
  );

  /** One-shot GSAP soften-in on hero card (paired with Framer image cross-fade). */
  useLayoutEffect(() => {
    if (reduceMotion || !heroPanelRef.current) return;
    const panel = heroPanelRef.current;
    const ctx = gsap.context(() => {
      gsap.from(panel, {
        y: 10,
        opacity: 0.75,
        duration: 0.55,
        ease: "power3.out",
        clearProps: "transform,opacity",
      });
    }, panel);
    return () => ctx.revert();
  }, [product.id, reduceMotion]);

  return (
    <motion.div
      className="mx-auto w-full max-w-5xl px-[max(0.875rem,env(safe-area-inset-left))] py-6 pr-[max(0.875rem,env(safe-area-inset-right))] sm:px-6 sm:py-10"
      initial="hidden"
      animate="show"
      variants={{
        hidden: {},
        show: {
          transition: { staggerChildren: reduceMotion ? 0 : 0.08 },
        },
      }}
    >
      <motion.div variants={fadeUp} className="mb-6">
        <motion.div whileHover={{ x: -3 }} transition={{ type: "spring", stiffness: 400, damping: 24 }}>
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm font-semibold"
            style={{ color: colors.primary }}
          >
            <PhosphorIcon
              icon={ArrowLeft}
              size="sm"
              weight="bold"
              color={colors.primary}
            />
            Back to shop
          </Link>
        </motion.div>
      </motion.div>

      <div className="grid gap-8 lg:grid-cols-2">
        <motion.div
          variants={fadeUp}
          className="space-y-3"
          onMouseEnter={() => setGalleryHoverPause(true)}
          onMouseLeave={() => setGalleryHoverPause(false)}
          onFocusCapture={() => setGalleryHoverPause(true)}
          onBlurCapture={(e) => {
            if (!e.currentTarget.contains(e.relatedTarget as Node | null)) {
              setGalleryHoverPause(false);
            }
          }}
        >
          <div
            ref={heroPanelRef}
            className="overflow-hidden rounded-xl border sm:rounded-2xl"
            style={{ borderColor: colors.border, backgroundColor: colors.card }}
          >
            <motion.div
              layout
              className="aspect-square w-full overflow-hidden"
              style={{ backgroundColor: colors.pageGradientMid }}
              key={`${imgIndex}-${images[Math.min(imgIndex, Math.max(images.length - 1, 0))] ?? "ph"}`}
              initial={
                reduceMotion ? false : { opacity: 0.85, scale: 1.04 }
              }
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
            >
              {images.length > 0 ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={images[Math.min(imgIndex, images.length - 1)]}
                  alt=""
                  width={1080}
                  height={1080}
                  className="h-full w-full object-cover"
                />
              ) : (
                <div
                  className="flex h-full w-full items-center justify-center p-6 text-center text-sm font-medium"
                  style={{ color: colors.textSecondary }}
                >
                  {product.title}
                </div>
              )}
            </motion.div>
          </div>

          {images.length > 1 ? (
            <div className="flex snap-x snap-mandatory gap-3 overflow-x-auto pb-2 pt-1 [-webkit-overflow-scrolling:touch] [scrollbar-width:thin]">
              {images.map((u, i) => (
                <motion.button
                  key={u}
                  type="button"
                  onClick={() => setImgIndex(i)}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.96 }}
                  className="h-[4.75rem] w-[4.75rem] shrink-0 snap-start touch-manipulation overflow-hidden rounded-xl border sm:h-16 sm:w-16"
                  style={{
                    borderColor: i === imgIndex ? colors.primary : colors.border,
                  }}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={u}
                    alt=""
                    width={1080}
                    height={1080}
                    className="h-full w-full object-cover"
                  />
                </motion.button>
              ))}
            </div>
          ) : null}
        </motion.div>

        <motion.div variants={fadeUp} className="space-y-4">
          <CategoryPill category={product.category} />
          <div>
            <motion.h1
              className="mt-2 text-xl font-extrabold leading-snug tracking-tight sm:text-3xl"
              style={{ color: colors.textPrimary }}
              initial={reduceMotion ? false : { opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
            >
              {product.title}
            </motion.h1>
            {subtitleLine ? (
              <p
                className="mt-2 text-sm leading-relaxed sm:text-base"
                style={{ color: colors.textSecondary }}
              >
                {subtitleLine}
              </p>
            ) : null}
            {!product.inStock ? (
              <p
                className="mt-3 rounded-xl border px-3 py-2 text-sm font-semibold"
                style={{ borderColor: colors.border, color: colors.textSecondary }}
              >
                Currently out of stock.
              </p>
            ) : null}
          </div>

          {lineHighlights.length > 0 ? (
            <motion.div className="space-y-2" variants={fadeUp}>
              <h2
                className="text-sm font-extrabold tracking-wide"
                style={{ color: colors.primary }}
              >
                Highlights
              </h2>
              <HighlightChipsRow
                highlights={lineHighlights}
                onPick={(t) => setModalTag(t)}
              />
            </motion.div>
          ) : null}

          {!available ? (
            <motion.div
              className="rounded-2xl border px-4 py-3 text-sm font-semibold"
              style={{ borderColor: colors.border, color: colors.textSecondary }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
            >
              This product is not available for purchase right now.
            </motion.div>
          ) : null}

          <div className="space-y-3">
            <h2
              className="text-sm font-extrabold tracking-wide"
              style={{ color: colors.primary }}
            >
              Choose a kit
            </h2>
            {kits.length === 0 ? (
              <p className="text-sm" style={{ color: colors.textSecondary }}>
                This product has no kits yet.
              </p>
            ) : (
              <LayoutGroup id={`kits-${product.id}`}>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                  {kits.map((kit) => {
                    const active = kit.lineId === selected?.lineId;
                    return (
                      <motion.button
                        key={kit.lineId}
                        type="button"
                        layout
                        onClick={() => setLineId(kit.lineId)}
                        whileHover={
                          reduceMotion ? {} : { y: -4, transition: { duration: 0.2 } }
                        }
                        whileTap={reduceMotion ? {} : { scale: 0.98 }}
                        className="relative overflow-hidden rounded-2xl border-2 px-4 py-5 text-left shadow-sm touch-manipulation sm:py-4"
                        style={{
                          borderColor: active ? colors.primary : colors.border,
                          backgroundColor: active ? `${colors.primary}0f` : colors.card,
                        }}
                      >
                        {active ? (
                          <motion.span
                            layoutId="kit-glow-ring"
                            className="pointer-events-none absolute inset-0 rounded-2xl"
                            style={{
                              boxShadow: `inset 0 0 0 2px ${colors.primary}`,
                            }}
                            transition={{
                              type: "spring",
                              stiffness: 360,
                              damping: 28,
                            }}
                          />
                        ) : null}
                        <div
                          className="relative flex flex-col gap-1"
                          style={{ color: colors.textPrimary }}
                        >
                          <span className="text-xs font-semibold uppercase tracking-wide opacity-75">
                            {kit.label}
                          </span>
                          <span className="text-2xl font-black tabular-nums">
                            ₹{kit.priceInr.toLocaleString("en-IN")}
                          </span>
                          <span
                            className="text-[11px] font-medium"
                            style={{ color: colors.textSecondary }}
                          >
                            {active
                              ? "Showing kit contents below"
                              : "Tap to see kit contents"}
                          </span>
                        </div>
                      </motion.button>
                    );
                  })}
                </div>
              </LayoutGroup>
            )}

            <AnimatePresence mode="wait">
              {selected ? (
                <motion.div
                  key={selected.lineId}
                  initial={
                    reduceMotion
                      ? { opacity: 0 }
                      : { opacity: 0, y: 10, scale: 0.99 }
                  }
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={
                    reduceMotion
                      ? { opacity: 0 }
                      : { opacity: 0, y: -8, scale: 0.995 }
                  }
                  transition={{
                    duration: reduceMotion ? 0.15 : 0.32,
                    ease: [0.22, 1, 0.36, 1],
                  }}
                  className="rounded-2xl border px-4 py-4 sm:px-5"
                  style={{
                    borderColor: colors.border,
                    backgroundColor: colors.card,
                  }}
                >
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                      <div
                        className="font-semibold"
                        style={{ color: colors.textPrimary }}
                      >
                        {selected.label}
                      </div>
                      <div
                        className="text-sm"
                        style={{ color: colors.textSecondary }}
                      >
                        ₹{selected.priceInr.toLocaleString("en-IN")} · selected
                      </div>
                    </div>
                  <div className="flex w-full flex-shrink-0 flex-col gap-2 sm:max-w-[min(100%,360px)] sm:flex-row sm:items-center sm:justify-end">
                    <motion.button
                      type="button"
                      disabled={!available}
                      whileHover={
                        reduceMotion ? {} : { scale: available ? 1.03 : 1 }
                      }
                      whileTap={
                        reduceMotion ? {} : { scale: available ? 0.97 : 1 }
                      }
                      className="inline-flex w-full min-h-12 touch-manipulation items-center justify-center rounded-full border-2 px-5 py-3 text-[15px] font-semibold shadow-sm disabled:cursor-not-allowed disabled:opacity-45 sm:w-auto sm:min-h-0 sm:min-w-[128px] sm:py-2.5 sm:text-sm"
                      style={{
                        borderColor: colors.primary,
                        color: colors.primary,
                        backgroundColor: colors.card,
                      }}
                      onClick={() => {
                        if (!available || !selected) return;
                        cart.buyNow({
                          productId: product.id,
                          productTitle: product.title,
                          lineId: selected.lineId,
                          kitLabel: selected.label,
                          priceInr: selected.priceInr,
                          qty: 1,
                        });
                        router.push("/cart");
                      }}
                    >
                      Buy now
                    </motion.button>
                    <motion.button
                      type="button"
                      disabled={!available}
                      whileHover={
                        reduceMotion ? {} : { scale: available ? 1.03 : 1 }
                      }
                      whileTap={
                        reduceMotion ? {} : { scale: available ? 0.97 : 1 }
                      }
                      className="inline-flex w-full min-h-12 shrink-0 touch-manipulation items-center justify-center rounded-full px-6 py-3 text-[15px] font-semibold text-white shadow-md disabled:cursor-not-allowed disabled:opacity-45 sm:w-auto sm:min-h-0 sm:min-w-[128px] sm:py-2.5 sm:text-sm"
                      style={{
                        background: `linear-gradient(135deg, ${colors.primary}, #43A047)`,
                      }}
                      onClick={() =>
                        cart.add({
                          productId: product.id,
                          productTitle: product.title,
                          lineId: selected.lineId,
                          kitLabel: selected.label,
                          priceInr: selected.priceInr,
                          qty: 1,
                        })
                      }
                    >
                      Add to cart
                    </motion.button>
                  </div>
                  </div>
                  <p
                    className="mt-2 text-[11px] leading-snug sm:text-right"
                    style={{ color: colors.textSecondary }}
                  >
                    Buy now replaces the rest of your cart with this kit and opens the cart page.
                  </p>

                  <div className="mt-4 border-t pt-4" style={{ borderColor: colors.border }}>
                    <motion.div
                      className="text-xs font-extrabold uppercase tracking-wide"
                      style={{ color: colors.primary }}
                      layout
                    >
                      What&apos;s inside
                    </motion.div>
                    {inclusionEntries.length > 0 ? (
                      <InclusionListGsap
                        animationKey={inclusionAnimKey}
                        entries={inclusionEntries}
                        lineColor={colors.textPrimary}
                        borderColor={colors.border}
                      />
                    ) : (
                      <p
                        className="mt-2 text-sm"
                        style={{ color: colors.textSecondary }}
                      >
                        No checklist items configured for this kit yet.
                      </p>
                    )}
                  </div>
                </motion.div>
              ) : null}
            </AnimatePresence>
          </div>
        </motion.div>
      </div>

      <HighlightDetailModal
        tag={modalTag}
        open={modalTag != null}
        onClose={() => setModalTag(null)}
      />
    </motion.div>
  );
}
