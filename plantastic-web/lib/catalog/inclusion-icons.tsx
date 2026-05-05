import type { ComponentType } from "react";
import type { PlantasticPhosphorIconProps } from "@/components/phosphor-icon";
import { CheckCircle } from "@phosphor-icons/react/dist/csr/CheckCircle";
import { Drop } from "@phosphor-icons/react/dist/csr/Drop";
import { Flower } from "@phosphor-icons/react/dist/csr/Flower";
import { Hand } from "@phosphor-icons/react/dist/csr/Hand";
import { Leaf } from "@phosphor-icons/react/dist/csr/Leaf";
import { Package } from "@phosphor-icons/react/dist/csr/Package";
import { Recycle } from "@phosphor-icons/react/dist/csr/Recycle";
import { Shovel } from "@phosphor-icons/react/dist/csr/Shovel";
import { Spade } from "@phosphor-icons/react/dist/csr/Spade";
import { Towel } from "@phosphor-icons/react/dist/csr/Towel";
import { colors } from "@/lib/theme/colors";
import {
  coconutCoir,
  compostItem,
  gloves,
  scoop,
  seedPacket,
  soilMix,
  towel,
} from "@/lib/catalog/kit-catalog";

export type InclusionIconComponent =
  ComponentType<PlantasticPhosphorIconProps>;

/** Visual grouping for icons + per-kind accent (white rows, colored icons only). */
type InclusionVisualKind =
  | "flower"
  | "seedPacket"
  | "soil"
  | "compost"
  | "coir"
  | "water"
  | "towel"
  | "gloves"
  | "scoop"
  | "fertilizer"
  | "generic";

const KIND_ICON: Record<InclusionVisualKind, InclusionIconComponent> = {
  flower: Flower,
  seedPacket: Package,
  soil: Spade,
  compost: Recycle,
  coir: Drop,
  water: Drop,
  towel: Towel,
  gloves: Hand,
  scoop: Shovel,
  fertilizer: Leaf,
  generic: CheckCircle,
};

/** Fill color per inclusion kind — icons only; rows use white background. */
const KIND_ICON_COLOR: Record<InclusionVisualKind, string> = {
  flower: "#EC407A",
  seedPacket: "#FF7043",
  soil: "#6D4C41",
  compost: "#388E3C",
  coir: "#00897B",
  water: "#1976D2",
  towel: "#8E24AA",
  gloves: "#E65100",
  scoop: "#5D4037",
  fertilizer: "#689F38",
  generic: colors.primary,
};

function heuristicKind(label: string): InclusionVisualKind {
  const L = label.toLowerCase();
  if (/flower/i.test(L)) return "flower";
  if (/(seed|packet|variety)/i.test(L)) return "seedPacket";
  if (/(garden soil|soil mix|potting|soil\b)/i.test(L)) return "soil";
  if (/compost/i.test(L)) return "compost";
  if (/(coir|coconut)/i.test(L)) return "coir";
  if (/towel/i.test(L)) return "towel";
  if (/glove/i.test(L)) return "gloves";
  if (/(scoop|trowel|shovel|\bspade\b)/i.test(L)) return "scoop";
  if (/(water|spray|bottle|mister)/i.test(L)) return "water";
  if (/(fertil|plant food|nutrient)/i.test(L)) return "fertilizer";
  return "generic";
}

function resolveInclusionKind(
  catalogId: string,
  label: string,
): InclusionVisualKind {
  /** Label wins so “Flower seed” stays the flower chip even with a seed UUID. */
  if (/flower/i.test(label)) return "flower";
  const id = catalogId.trim();
  if (id === seedPacket) return "seedPacket";
  if (id === soilMix) return "soil";
  if (id === compostItem) return "compost";
  if (id === coconutCoir) return "coir";
  if (id === towel) return "towel";
  if (id === gloves) return "gloves";
  if (id === scoop) return "scoop";
  return heuristicKind(label);
}

/** Phosphor icon for a “What’s inside” row (catalog id when known, else label heuristics). */
export function phosphorIconForInclusion(
  catalogId: string,
  label: string,
): InclusionIconComponent {
  return KIND_ICON[resolveInclusionKind(catalogId, label)];
}

/** Solid accent for “What’s inside” row icons (pairs with `weight="fill"`). */
export function inclusionIconColor(
  catalogId: string,
  label: string,
): string {
  return KIND_ICON_COLOR[resolveInclusionKind(catalogId, label)];
}
