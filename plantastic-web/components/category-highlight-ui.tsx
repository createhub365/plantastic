"use client";

import { motion, useReducedMotion } from "framer-motion";
import { Flower } from "@phosphor-icons/react/dist/csr/Flower";
import { Plant } from "@phosphor-icons/react/dist/csr/Plant";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import { pillText } from "@/lib/catalog/highlight-tags";
import {
  highlightGlyphOnGradient,
  highlightPhosphorIcon,
} from "@/lib/highlight/highlight-phosphor";
import { gradientStyle } from "@/lib/highlight/highlight-style";
import { colors } from "@/lib/theme/colors";
import { PhosphorIcon } from "@/components/phosphor-icon";

export function CategoryPill({ category }: { category: string }) {
  const flower = category.trim() === "Flower seed";
  const reduce = useReducedMotion();
  const iconColor = flower ? "#EC407A" : colors.primary;

  return (
    <motion.span
      className="inline-flex max-w-full items-center gap-1.5 self-start rounded-full border bg-white px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide shadow-[0_1px_3px_rgba(0,0,0,0.06)]"
      style={{
        borderColor: colors.border,
        color: colors.textPrimary,
      }}
      initial={reduce ? false : { scale: 0.94, opacity: 0, y: 4 }}
      animate={{ scale: 1, opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 440, damping: 26 }}
      whileHover={reduce ? undefined : { scale: 1.02, y: -1 }}
    >
      <PhosphorIcon
        icon={flower ? Flower : Plant}
        size="sm"
        weight="fill"
        color={iconColor}
      />
      <span className="truncate normal-case tracking-normal">{category}</span>
    </motion.span>
  );
}

export function HighlightChipsRow({
  highlights,
  onPick,
}: {
  highlights: HighlightTag[];
  onPick: (tag: HighlightTag) => void;
}) {
  const reduce = useReducedMotion();

  if (highlights.length === 0) return null;

  return (
    <motion.div
      className="flex flex-wrap gap-2"
      initial={reduce ? false : "hidden"}
      animate="show"
      variants={{
        hidden: {},
        show: { transition: { staggerChildren: reduce ? 0 : 0.07 } },
      }}
    >
      {highlights.map((tag) => (
        <motion.button
          key={tag.id}
          type="button"
          onClick={() => onPick(tag)}
          variants={{
            hidden: { opacity: 0, y: 10, scale: 0.94 },
            show: {
              opacity: 1,
              y: 0,
              scale: 1,
              transition: { type: "spring", stiffness: 400, damping: 22 },
            },
          }}
          whileHover={reduce ? undefined : { scale: 1.02 }}
          whileTap={reduce ? undefined : { scale: 0.97 }}
          className="inline-flex items-center gap-1.5 rounded-full border border-white/50 px-3 py-1.5 text-left text-sm font-bold text-white shadow-md"
          style={{
            ...gradientStyle(tag.iconKey),
            textShadow: "0 1px 6px rgba(0,0,0,0.35)",
          }}
        >
          <PhosphorIcon
            icon={highlightPhosphorIcon(tag.iconKey)}
            size="md"
            weight="fill"
            color={highlightGlyphOnGradient}
            className="drop-shadow-[0_1px_2px_rgba(0,0,0,0.25)]"
          />
          <span>{pillText(tag)}</span>
        </motion.button>
      ))}
    </motion.div>
  );
}
