"use client";

import NextLink from "next/link";
import { motion, useReducedMotion } from "framer-motion";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import { highlightsForProduct } from "@/lib/catalog/highlight-tags";
import { effectiveNetworkCoverUrl } from "@/lib/catalog/parse-product";
import type { ShopProduct } from "@/lib/catalog/types";
import { CategoryPill } from "@/components/category-highlight-ui";
import { HighlightDots } from "@/components/highlight-dots";
import { cardLift } from "@/lib/motion/variants";
import { colors } from "@/lib/theme/colors";

const MotionLink = motion.create(NextLink);

export function ProductCard({
  product,
  highlightCatalog,
}: {
  product: ShopProduct;
  highlightCatalog: HighlightTag[];
}) {
  const reduce = useReducedMotion();
  const img = effectiveNetworkCoverUrl(product);
  const href = `/products/${encodeURIComponent(product.id)}`;
  const muted = !(product.inStock && product.visibleInShop);
  const lineHighlights = highlightsForProduct(
    product.highlightTagIds,
    highlightCatalog,
  );
  const kitsLabel =
    product.kits.length === 1 ? "1 kit" : `${product.kits.length} kits`;

  return (
    <MotionLink
      href={href}
      className="group flex min-w-0 flex-col overflow-hidden rounded-2xl border shadow-[0_2px_14px_rgba(0,0,0,0.06)] ring-1 ring-black/[0.03] transition-[box-shadow] duration-300 hover:shadow-[0_8px_26px_rgba(46,125,50,0.12)] hover:ring-black/[0.05]"
      style={{
        borderColor: colors.border,
        backgroundColor: colors.card,
      }}
      variants={reduce ? undefined : cardLift}
      initial="rest"
      whileHover={reduce ? undefined : "hover"}
      whileTap={reduce ? undefined : "tap"}
    >
      <div className="relative overflow-hidden">
        <motion.div
          className="relative aspect-square w-full overflow-hidden"
          style={{ backgroundColor: colors.pageGradientMid }}
        >
          {img ? (
            <motion.img
              src={img}
              alt=""
              width={1080}
              height={1080}
              className="h-full w-full object-cover"
              loading="lazy"
              whileHover={reduce ? undefined : { scale: 1.05 }}
              transition={{ type: "spring", stiffness: 280, damping: 22 }}
            />
          ) : (
            <div
              className="flex h-full w-full items-center justify-center px-4 text-center text-sm font-medium"
              style={{ color: colors.textSecondary }}
            >
              {product.title}
            </div>
          )}
          {muted ? (
            <div className="absolute inset-0 flex items-start justify-end bg-black/40 p-2">
              <span className="rounded-lg bg-orange-400/95 px-2 py-0.5 text-[10px] font-extrabold text-black shadow">
                {product.visibleInShop ? "Out of stock" : "Unavailable"}
              </span>
            </div>
          ) : null}
        </motion.div>
      </div>

      <div
        className="flex flex-1 flex-col gap-2 border-t bg-white p-3.5 sm:p-4"
        style={{ borderColor: colors.border }}
      >
        <CategoryPill category={product.category} />
        <div className="flex items-baseline justify-between gap-3">
          <div
            className={`line-clamp-2 min-w-0 flex-1 text-[16px] font-bold leading-tight tracking-tight sm:text-[17px] ${
              muted ? "opacity-45" : ""
            }`}
            style={{
              color: colors.primary,
              fontFamily: "Georgia, 'Times New Roman', serif",
            }}
          >
            {product.title}
          </div>
          <span
            className="shrink-0 rounded-full px-1.5 py-px text-[10px] font-bold tabular-nums tracking-wide"
            style={{
              color: colors.textSecondary,
              backgroundColor: colors.pageGradientMid,
            }}
          >
            {kitsLabel}
          </span>
        </div>
        <HighlightDots highlights={lineHighlights} max={3} />
      </div>
    </MotionLink>
  );
}
