import type { Variants } from "framer-motion";

export const cardLift = {
  rest: { y: 0, boxShadow: "0 4px 14px rgba(0,0,0,0.06)" },
  hover: {
    y: -5,
    boxShadow: "0 14px 28px rgba(46,125,50,0.14)",
    transition: { type: "spring", stiffness: 380, damping: 22 },
  },
  tap: { scale: 0.985 },
} as const;

export const staggerContainer: Variants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.065,
      delayChildren: 0.06,
    },
  },
};

export const staggerItem: Variants = {
  hidden: { opacity: 0, y: 14 },
  show: {
    opacity: 1,
    y: 0,
    transition: { type: "spring", stiffness: 420, damping: 26 },
  },
};

export const fadeUp: Variants = {
  hidden: { opacity: 0, y: 12 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.42, ease: [0.22, 1, 0.36, 1] },
  },
};
