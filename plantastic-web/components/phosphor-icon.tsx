"use client";

import type { ComponentType } from "react";

/** Pixel sizes aligned with Tailwind-ish UI chrome (matches text-sm/md rows). */
export const phosphorPx = {
  xs: 14,
  sm: 16,
  md: 20,
  lg: 22,
  xl: 24,
  "2xl": 28,
} as const;

export type PhosphorSize = keyof typeof phosphorPx;

export type PhosphorWeight =
  | "thin"
  | "light"
  | "regular"
  | "bold"
  | "fill"
  | "duotone";

/** Props shared by csr Phosphor icon components used in Plantastic. */
export type PlantasticPhosphorIconProps = {
  alt?: string;
  color?: string;
  size?: number | string;
  weight?: PhosphorWeight;
  mirrored?: boolean;
  className?: string;
};

type Props = {
  icon: ComponentType<PlantasticPhosphorIconProps>;
  size?: PhosphorSize;
  /** @default regular */
  weight?: PhosphorWeight;
  className?: string;
  /** Forwarded as Phosphor `color` prop (usually hex). */
  color?: string;
};

/**
 * Consistent sizing + shrink for Phosphor icons. Import icons per-file, e.g.
 * `import { ShoppingCart } from "@phosphor-icons/react/dist/csr/ShoppingCart"`.
 */
export function PhosphorIcon({
  icon: Icon,
  size = "md",
  weight = "regular",
  className,
  color,
}: Props) {
  return (
    <Icon
      size={phosphorPx[size]}
      weight={weight}
      color={color}
      aria-hidden
      className={`shrink-0 ${className ?? ""}`.trim()}
    />
  );
}
