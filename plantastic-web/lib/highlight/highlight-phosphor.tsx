"use client";

import type { ComponentType } from "react";
import type { PlantasticPhosphorIconProps } from "@/components/phosphor-icon";
import { Drop } from "@phosphor-icons/react/dist/csr/Drop";
import { Flower } from "@phosphor-icons/react/dist/csr/Flower";
import { FlowerLotus } from "@phosphor-icons/react/dist/csr/FlowerLotus";
import { Heart } from "@phosphor-icons/react/dist/csr/Heart";
import { House } from "@phosphor-icons/react/dist/csr/House";
import { Leaf } from "@phosphor-icons/react/dist/csr/Leaf";
import { Lightning } from "@phosphor-icons/react/dist/csr/Lightning";
import { Plant } from "@phosphor-icons/react/dist/csr/Plant";
import { Recycle } from "@phosphor-icons/react/dist/csr/Recycle";
import { Sparkle } from "@phosphor-icons/react/dist/csr/Sparkle";
import { Stethoscope } from "@phosphor-icons/react/dist/csr/Stethoscope";
import { Sun } from "@phosphor-icons/react/dist/csr/Sun";
import { TreeEvergreen } from "@phosphor-icons/react/dist/csr/TreeEvergreen";
import { Wind } from "@phosphor-icons/react/dist/csr/Wind";

export type HighlightGlyphIcon = ComponentType<PlantasticPhosphorIconProps>;

/** Phosphor icon for each Flutter/admin `highlightDetailDecoration` `iconKey`. */
export function highlightPhosphorIcon(iconKey: string): HighlightGlyphIcon {
  const k = iconKey.trim();
  switch (k) {
    case "eco":
      return Leaf;
    case "local_florist":
      return Flower;
    case "air":
    case "air_purifying":
      return Wind;
    case "oxygen":
      return Sparkle;
    case "home":
      return House;
    case "vastu":
      return FlowerLotus;
    case "forest":
      return TreeEvergreen;
    case "water_drop":
      return Drop;
    case "wb_sunny":
      return Sun;
    case "energy":
      return Lightning;
    case "favorite":
      return Heart;
    case "health":
      return Stethoscope;
    case "recycling":
      return Recycle;
    case "compost":
      return Plant;
    default:
      return Plant;
  }
}

/** Readable on busy gradient headers (chips, dots, modal). */
export const highlightGlyphOnGradient = "rgba(255,255,255,0.95)";
