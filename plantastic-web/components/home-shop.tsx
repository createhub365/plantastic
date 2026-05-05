"use client";

import {
  motion,
  useReducedMotion,
} from "framer-motion";
import { useMemo, useState, type ComponentType } from "react";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import type { ShopHomeBanner, ShopProduct } from "@/lib/catalog/types";
import type { HomeBrowseTab } from "@/lib/catalog/browse";
import { visibleForBrowse } from "@/lib/catalog/browse";
import { HomeHero } from "@/components/home-hero";
import { PhosphorIcon } from "@/components/phosphor-icon";
import { ProductGrid } from "@/components/product-grid";
import { fadeUp } from "@/lib/motion/variants";
import { colors } from "@/lib/theme/colors";
import { Fire } from "@phosphor-icons/react/dist/csr/Fire";
import { Flower } from "@phosphor-icons/react/dist/csr/Flower";
import { Leaf } from "@phosphor-icons/react/dist/csr/Leaf";
import { MagnifyingGlass } from "@phosphor-icons/react/dist/csr/MagnifyingGlass";
import { Package } from "@phosphor-icons/react/dist/csr/Package";
import { Plant } from "@phosphor-icons/react/dist/csr/Plant";
import type { PlantasticPhosphorIconProps } from "@/components/phosphor-icon";

type BrowseTabUi = {
  id: HomeBrowseTab;
  label: string;
  icon: ComponentType<PlantasticPhosphorIconProps>;
  /** Saturated icon + label when tab is selected. */
  accent: string;
  /** Softer hue for inactive icon (still colorful, not gray). */
  iconMuted: string;
  /** Tinted pill when selected (with accent border). */
  activeBg: string;
};

const tabs: BrowseTabUi[] = [
  {
    id: "flowers",
    label: "Flower seeds",
    icon: Flower,
    accent: "#C2185B",
    iconMuted: "#EC407A",
    activeBg: "#FCE4EC",
  },
  {
    id: "plants",
    label: "Plant seeds",
    icon: Plant,
    accent: "#2E7D32",
    iconMuted: "#66BB6A",
    activeBg: "#E8F5E9",
  },
  {
    id: "starterKits",
    label: "Starter kits",
    icon: Package,
    accent: "#E65100",
    iconMuted: "#FF9800",
    activeBg: "#FFF3E0",
  },
  {
    id: "bestSellers",
    label: "Best sellers",
    icon: Fire,
    accent: "#F57C00",
    iconMuted: "#FFB74D",
    activeBg: "#FFF8E1",
  },
];

export function HomeShop({
  products,
  banner,
  highlightCatalog,
}: {
  products: ShopProduct[];
  banner: ShopHomeBanner;
  highlightCatalog: HighlightTag[];
}) {
  const reduce = useReducedMotion();
  const [tab, setTab] = useState<HomeBrowseTab>("flowers");
  const [query, setQuery] = useState("");

  const shop = useMemo(
    () => products.filter((p) => p.visibleInShop),
    [products],
  );

  const visible = useMemo(() => visibleForBrowse(shop, tab), [shop, tab]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return visible;
    return visible.filter(
      (p) =>
        p.title.toLowerCase().includes(q) ||
        p.subtitle.toLowerCase().includes(q),
    );
  }, [visible, query]);

  return (
    <div className="mx-auto w-full max-w-6xl space-y-5 px-4 pb-16 pt-4 sm:space-y-6 sm:px-6 sm:pb-20 sm:pt-6">
      <motion.div variants={fadeUp} initial="hidden" animate="show">
        <HomeHero config={banner} />
      </motion.div>

      <motion.div
        className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"
        initial={reduce ? false : { opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: reduce ? 0 : 0.08, duration: 0.45 }}
      >
        <div className="flex gap-3">
          <span className="flex h-[42px] w-[42px] shrink-0 items-center justify-center">
            <Leaf
              size={42}
              weight="fill"
              color={colors.primary}
              aria-hidden
              className="shrink-0 drop-shadow-sm"
            />
          </span>
          <div>
            <motion.h1
              className="text-xl font-semibold tracking-tight sm:text-2xl"
              style={{ color: colors.textPrimary }}
              layout
            >
              Shop
            </motion.h1>
            <motion.p
              className="mt-1 text-sm"
              style={{ color: colors.textSecondary }}
              initial={reduce ? false : { opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.12 }}
            >
              Fresh picks for balcony, kitchen, and garden.
            </motion.p>
          </div>
        </div>

        <label className="relative w-full sm:max-w-sm">
          <span className="sr-only">Search products</span>
          <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2">
            <PhosphorIcon
              icon={MagnifyingGlass}
              size="md"
              weight="bold"
              color={colors.textSecondary}
            />
          </span>
          <motion.input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by name…"
            className="w-full rounded-full border py-2 pl-10 pr-4 text-sm outline-none ring-0"
            style={{ borderColor: colors.border, backgroundColor: colors.card }}
            whileFocus={reduce ? undefined : { scale: 1.02 }}
          />
        </label>
      </motion.div>

      <motion.div className="-mx-1 flex gap-2 overflow-x-auto px-1 py-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {tabs.map((t) => {
          const active = t.id === tab;
          return (
            <motion.button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              layout
              whileHover={reduce ? undefined : { y: -2 }}
              whileTap={reduce ? undefined : { scale: 0.97 }}
              transition={{ type: "spring", stiffness: 440, damping: 28 }}
              className="relative inline-flex shrink-0 items-center gap-2 rounded-full border px-3 py-1.5 text-sm font-semibold"
              style={{
                borderColor: active ? t.accent : colors.border,
                backgroundColor: active ? t.activeBg : colors.card,
                color: active ? t.accent : colors.textPrimary,
              }}
            >
              <PhosphorIcon
                icon={t.icon}
                size="sm"
                weight="fill"
                color={active ? t.accent : t.iconMuted}
              />
              {t.label}
            </motion.button>
          );
        })}
      </motion.div>

      <ProductGrid
        key={`${tab}-${filtered.map((p) => p.id).join(",")}`}
        products={filtered}
        highlightCatalog={highlightCatalog}
      />
    </div>
  );
}
