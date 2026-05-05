"use client";

import { motion } from "framer-motion";

/**
 * Wraps route segments — App Router remounts `template.tsx` per navigation,
 * giving a subtle page soften-in (plus `layout.tsx` chrome stays put).
 */
export default function RootTemplate({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}
