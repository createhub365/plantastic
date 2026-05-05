import type { CSSProperties } from "react";

/** Maps Flutter `highlightDetailDecoration` + sensible emoji for web chips. */

export function highlightGradient(iconKey: string): [string, string] {
  const k = iconKey.trim();
  switch (k) {
    case "eco":
      return ["#1B4332", "#40916C"];
    case "local_florist":
      return ["#841E5C", "#F06292"];
    case "air":
    case "air_purifying":
      return ["#01579B", "#4FC3F7"];
    case "oxygen":
      return ["#00695C", "#4DB6AC"];
    case "home":
      return ["#B45309", "#FBBF24"];
    case "vastu":
      return ["#4A148C", "#BA68C8"];
    case "forest":
      return ["#1B3314", "#558B2F"];
    case "water_drop":
      return ["#0D47A1", "#29B6F6"];
    case "wb_sunny":
      return ["#E65100", "#FFD54F"];
    case "energy":
      return ["#4A148C", "#FF5252"];
    case "favorite":
      return ["#B71C1C", "#FF8A80"];
    case "health":
      return ["#004D40", "#69F0AE"];
    case "recycling":
      return ["#1B5E20", "#00BFA5"];
    case "compost":
      return ["#3E2723", "#8D6E63"];
    default:
      return ["#006064", "#26C6DA"];
  }
}

export function highlightEmoji(iconKey: string): string {
  const k = iconKey.trim();
  switch (k) {
    case "eco":
      return "🌱";
    case "local_florist":
      return "🌸";
    case "air":
    case "air_purifying":
      return "💨";
    case "oxygen":
      return "✨";
    case "home":
      return "🏠";
    case "vastu":
      return "🪷";
    case "forest":
      return "🌲";
    case "water_drop":
      return "💧";
    case "wb_sunny":
      return "☀️";
    case "energy":
      return "⚡";
    case "favorite":
      return "❤️";
    case "health":
      return "🩺";
    case "recycling":
      return "♻️";
    case "compost":
      return "🍂";
    default:
      return "🌿";
  }
}

export function gradientStyle(iconKey: string): CSSProperties {
  const [a, b] = highlightGradient(iconKey);
  return {
    backgroundImage: `linear-gradient(135deg, ${a}, ${b})`,
  };
}
