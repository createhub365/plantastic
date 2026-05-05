"use client";

import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import type { KitInclusionEntry } from "@/lib/catalog/inclusions";
import {
  inclusionIconColor,
  phosphorIconForInclusion,
} from "@/lib/catalog/inclusion-icons";
import { PhosphorIcon } from "@/components/phosphor-icon";

type Props = {
  /** Changes when selected kit changes — re-runs stagger. */
  animationKey: string;
  /** Omitted or null only when callers pass bad data; treated as []. */
  entries?: KitInclusionEntry[] | null;
  lineColor: string;
  borderColor: string;
};

/** Soft wash behind icons from solid hex. */
function iconWellColor(hex: string, alpha = 0.16): string {
  const h = hex.replace("#", "").trim();
  if (h.length !== 6) return `rgba(46, 125, 50, ${alpha})`;
  const n = Number.parseInt(h, 16);
  const r = (n >> 16) & 255;
  const g = (n >> 8) & 255;
  const b = n & 255;
  return `rgba(${r},${g},${b},${alpha})`;
}

/**
 * GSAP stagger for “What’s inside” lines + icon pop (complements Framer section cross-fade).
 * Reduced motion honored via gsap.matchMedia.
 */
export function InclusionListGsap({
  animationKey,
  entries: entriesProp,
  lineColor,
  borderColor,
}: Props) {
  const entries = entriesProp ?? [];
  const listRef = useRef<HTMLUListElement>(null);

  useLayoutEffect(() => {
    const root = listRef.current;
    if (!root || entries.length === 0) return;

    const items = root.querySelectorAll<HTMLLIElement>(".inclusion-line");
    const iconWraps = root.querySelectorAll<HTMLElement>(".inclusion-icon-wrap");
    const mm = gsap.matchMedia();

    mm.add("(prefers-reduced-motion: no-preference)", () => {
      const ctx = gsap.context(() => {
        gsap.fromTo(
          items,
          { opacity: 0, x: -16, filter: "blur(6px)" },
          {
            opacity: 1,
            x: 0,
            filter: "blur(0px)",
            duration: 0.5,
            stagger: 0.072,
            ease: "power3.out",
            overwrite: "auto",
          },
        );
        gsap.fromTo(
          iconWraps,
          { scale: 0.35, rotate: -14, opacity: 0 },
          {
            scale: 1,
            rotate: 0,
            opacity: 1,
            duration: 0.58,
            stagger: 0.072,
            delay: 0.06,
            ease: "back.out(1.65)",
            overwrite: "auto",
          },
        );
      }, root);
      return () => ctx.revert();
    });

    mm.add("(prefers-reduced-motion: reduce)", () => {
      gsap.set(items, { opacity: 1, x: 0, filter: "none" });
      gsap.set(iconWraps, { scale: 1, rotate: 0, opacity: 1 });
    });

    return () => {
      mm.revert();
    };
  }, [animationKey, entries]);

  if (entries.length === 0) return null;

  return (
    <ul
      ref={listRef}
      className="mt-2 space-y-2 border-t pt-3 text-sm"
      style={{ borderColor, color: lineColor }}
    >
      {entries.map((entry, i) => {
        const Icon = phosphorIconForInclusion(entry.catalogId, entry.label);
        const iconTint = inclusionIconColor(entry.catalogId, entry.label);
        const key = `${entry.catalogId || "snap"}:${i}:${entry.label}`;
        return (
          <li
            key={key}
            className="inclusion-line flex items-center gap-3 rounded-2xl border bg-white px-3 py-2.5 shadow-[0_2px_12px_rgba(0,0,0,0.045)] transition-shadow duration-300 hover:shadow-[0_4px_18px_rgba(0,0,0,0.07)]"
            style={{ borderColor }}
          >
            <span
              className="inclusion-icon-wrap flex h-11 w-11 shrink-0 items-center justify-center rounded-xl shadow-[inset_0_1px_0_rgba(255,255,255,0.65)]"
              style={{ backgroundColor: iconWellColor(iconTint) }}
              aria-hidden
            >
              <PhosphorIcon
                icon={Icon}
                size="md"
                weight="fill"
                color={iconTint}
              />
            </span>
            <span
              className="min-w-0 flex-1 text-[15px] font-semibold leading-snug tracking-tight"
              style={{ color: lineColor }}
            >
              {entry.label}
            </span>
          </li>
        );
      })}
    </ul>
  );
}
