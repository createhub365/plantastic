"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import { pillText } from "@/lib/catalog/highlight-tags";
import {
  highlightGlyphOnGradient,
  highlightPhosphorIcon,
} from "@/lib/highlight/highlight-phosphor";
import { gradientStyle } from "@/lib/highlight/highlight-style";
import { PhosphorIcon } from "@/components/phosphor-icon";

/** Shop grid: small dots with tooltip — mirrors Flutter `_SubtitleHighlightIcon`. */
export function HighlightDots({
  highlights,
  max = 3,
}: {
  highlights: HighlightTag[];
  max?: number;
}) {
  const reduce = useReducedMotion();
  const slice = highlights.slice(0, max);

  if (slice.length === 0) return null;

  return (
    <motion.div
      className="flex flex-wrap items-center gap-2 pt-0.5"
      initial={reduce ? false : "hidden"}
      animate="show"
      variants={{
        hidden: {},
        show: { transition: { staggerChildren: reduce ? 0 : 0.09 } },
      }}
    >
      {slice.map((tag) => {
        const tip =
          tag.title.trim().length > 0 ? tag.title.trim() : pillText(tag);
        return (
          <motion.span
            key={tag.id}
            title={tip}
            variants={{
              hidden: { opacity: 0, scale: 0.4, y: 6, rotate: -12 },
              show: {
                opacity: 1,
                scale: 1,
                y: 0,
                rotate: 0,
                transition: { type: "spring", stiffness: 420, damping: 20 },
              },
            }}
            whileHover={
              reduce
                ? undefined
                : {
                    scale: 1.12,
                    y: -2,
                    transition: { type: "spring", stiffness: 500, damping: 18 },
                  }
            }
            whileTap={reduce ? undefined : { scale: 0.95 }}
            className="flex h-5 w-5 cursor-default items-center justify-center rounded-full border border-white/70 shadow-[0_2px_6px_rgba(0,0,0,0.12),inset_0_1px_0_rgba(255,255,255,0.35)] ring-1 ring-black/[0.04]"
            style={gradientStyle(tag.iconKey)}
          >
            <PhosphorIcon
              icon={highlightPhosphorIcon(tag.iconKey)}
              size="xs"
              weight="fill"
              color={highlightGlyphOnGradient}
            />
            <span className="sr-only">{tip}</span>
          </motion.span>
        );
      })}
    </motion.div>
  );
}
