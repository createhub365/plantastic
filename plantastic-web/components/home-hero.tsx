"use client";

import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { useEffect, useMemo, useState } from "react";
import { colors } from "@/lib/theme/colors";
import type { ShopHomeBanner } from "@/lib/catalog/types";
import {
  captionForSlide,
  effectiveHeroSlides,
} from "@/lib/catalog/home-banner";

function resolvedBannerHeightPx(config: ShopHomeBanner): number {
  const lo = config.bannerMinHeightPx;
  const hi = config.bannerMaxHeightPx;
  const h = config.bannerHeightPx;
  if (hi <= lo) return Math.min(Math.max(h, 100), 400);
  return Math.min(Math.max(h, lo), hi);
}

export function HomeHero({ config }: { config: ShopHomeBanner }) {
  const reduce = useReducedMotion();
  const slides = useMemo(() => effectiveHeroSlides(config), [config]);
  const heightPx = resolvedBannerHeightPx(config);
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (slides.length <= 1) return;
    const ms = Math.min(
      60_000,
      Math.max(1500, config.carouselIntervalMs || 5000),
    );
    const id = window.setInterval(() => {
      setIndex((i) => (i + 1) % slides.length);
    }, ms);
    return () => window.clearInterval(id);
  }, [slides.length, config.carouselIntervalMs, slides]);

  useEffect(() => {
    setIndex(0);
  }, [slides.length]);

  const showGradient = slides.length === 0;
  const active = slides[index];

  return (
    <section
      className="relative overflow-hidden rounded-2xl border shadow-sm"
      style={{ borderColor: colors.border, height: heightPx }}
    >
      {showGradient ? (
        <>
          <motion.div
            aria-hidden
            className="pointer-events-none absolute inset-0 opacity-90"
            animate={
              reduce
                ? {}
                : { scale: [1, 1.04, 1], opacity: [0.75, 1, 0.75] }
            }
            transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
            style={{
              background: `linear-gradient(125deg, ${colors.pageGradientTop} 0%, ${colors.accent}40 42%, ${colors.primaryLight}50 72%, ${colors.pageGradientMid} 100%)`,
            }}
          />
          <motion.div
            className="relative flex h-full w-full items-center justify-center px-6 text-center"
            initial={reduce ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6 }}
          >
            <motion.p
              className="relative z-[1] max-w-xl text-balance text-lg font-semibold leading-snug sm:text-xl"
              style={{ color: colors.textPrimary }}
              initial={reduce ? false : { y: 14, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: reduce ? 0 : 0.1, duration: 0.55 }}
            >
              {config.titleOverlay}
            </motion.p>
          </motion.div>
        </>
      ) : (
        <div className="relative h-full w-full overflow-hidden bg-black/5">
          <AnimatePresence initial={false} mode="sync">
            {active ? (
              <motion.div
                key={`${active.url}-${index}`}
                className="absolute inset-0"
                initial={reduce ? { opacity: 0 } : { opacity: 0, scale: 1.06 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={reduce ? { opacity: 0 } : { opacity: 0, scale: 0.98 }}
                transition={{
                  duration: reduce ? 0.2 : 0.65,
                  ease: [0.22, 1, 0.36, 1],
                }}
              >
                {active.kind === "video" ? (
                  <video
                    className="h-full w-full object-cover"
                    src={active.url}
                    muted
                    playsInline
                    autoPlay
                    loop
                    preload="metadata"
                  />
                ) : (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={active.url}
                    alt=""
                    className="h-full w-full object-cover"
                  />
                )}
                <div className="pointer-events-none absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/55 to-transparent px-4 py-3">
                  <motion.p
                    initial={reduce ? false : { y: 8, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.12, duration: 0.4 }}
                    className="text-sm font-semibold text-white drop-shadow-sm sm:text-base"
                  >
                    {captionForSlide(config, active)}
                  </motion.p>
                </div>
              </motion.div>
            ) : null}
          </AnimatePresence>
        </div>
      )}
    </section>
  );
}
