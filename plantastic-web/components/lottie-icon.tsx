"use client";

import Lottie, { type LottieRefCurrentProps } from "lottie-react";
import { useReducedMotion } from "framer-motion";
import { useEffect, useRef } from "react";
import flower from "@/lib/lottie/animations/flower.json";
import sprout from "@/lib/lottie/animations/sprout.json";

const DATA = {
  sprout,
  flower,
} as const;

export type LottieIconName = keyof typeof DATA;

type Props = {
  name: LottieIconName;
  className?: string;
  /** When set, exposed as accessible name; otherwise decorative. */
  label?: string;
};

export function LottieIcon({ name, className, label }: Props) {
  const reduce = useReducedMotion();
  const lottieRef = useRef<LottieRefCurrentProps>(null);

  useEffect(() => {
    if (!reduce) return;
    const inst = lottieRef.current;
    if (!inst) return;
    inst.goToAndStop(0, true);
  }, [reduce, name]);

  return (
    <span
      className={className}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <Lottie
        lottieRef={lottieRef}
        animationData={DATA[name]}
        loop={!reduce}
        autoplay={!reduce}
        className="h-full w-full"
      />
    </span>
  );
}
