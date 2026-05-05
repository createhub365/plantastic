"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import type { ShopProduct } from "@/lib/catalog/types";
import { ProductCard } from "@/components/product-card";
import { staggerContainer, staggerItem } from "@/lib/motion/variants";

export function ProductGrid({
  products,
  highlightCatalog,
}: {
  products: ShopProduct[];
  highlightCatalog: HighlightTag[];
}) {
  const reduce = useReducedMotion();

  if (products.length === 0) {
    return (
      <p className="rounded-2xl border border-dashed px-4 py-10 text-center text-sm text-[#6B6B6B]">
        No products in this section yet.
      </p>
    );
  }

  return (
    <motion.div
      key={products.map((p) => p.id).join(",")}
      className="grid grid-cols-2 gap-2.5 min-[390px]:gap-3 sm:gap-4 lg:grid-cols-3"
      variants={reduce ? undefined : staggerContainer}
      initial={reduce ? false : "hidden"}
      animate={reduce ? false : "show"}
    >
      {products.map((p) => (
        <motion.div
          key={p.id}
          variants={reduce ? undefined : staggerItem}
          className="min-w-0"
        >
          <ProductCard product={p} highlightCatalog={highlightCatalog} />
        </motion.div>
      ))}
    </motion.div>
  );
}
