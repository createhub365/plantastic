"use client";

import NextLink from "next/link";
import { motion } from "framer-motion";
import { useCallback, useState } from "react";
import { BrandMark } from "@/components/brand-mark";
import { colors } from "@/lib/theme/colors";

const MotionLink = motion.create(NextLink);

type Props = {
  reduceMotion: boolean | null;
};

/**
 * Mirrors Flutter [`PlantasticAppBar`](plantastic/lib/widgets/plantastic_app_bar.dart): `Logo.png` row + “Plantastic 🌿”.
 * Asset baked from Flutter at `plantastic/assets/Logo.png` → `public/brand/Logo.png`.
 */
export function PlantasticLogo({ reduceMotion }: Props) {
  const reduce = Boolean(reduceMotion);
  const [logoFailed, setLogoFailed] = useState(false);
  const onLogoError = useCallback(() => setLogoFailed(true), []);

  return (
    <MotionLink
      href="/"
      className="group flex min-w-0 items-center gap-2 truncate sm:gap-3"
      aria-label="Plantastic home"
      whileHover={reduce ? undefined : { scale: 1.02 }}
      whileTap={reduce ? undefined : { scale: 0.98 }}
    >
      {logoFailed ? (
        <BrandMark className="h-[42px] w-[42px] shrink-0 sm:h-[52px] sm:w-[52px]" />
      ) : (
        // Mirrors Image.asset(fit: BoxFit.contain); onError matches Flutter eco icon fallback shape.
        // eslint-disable-next-line @next/next/no-img-element -- onError fallback + sizing
        <img
          src="/brand/Logo.png"
          alt=""
          decoding="async"
          className="h-[46px] w-auto max-w-[min(40vw,190px)] shrink-0 object-contain object-left pointer-events-none sm:h-14"
          onError={onLogoError}
        />
      )}
      <span
        className="min-w-0 truncate text-[18px] font-semibold tracking-tight sm:text-xl"
        style={{ color: colors.textPrimary }}
      >
        Plantastic 🌿
      </span>
    </MotionLink>
  );
}
