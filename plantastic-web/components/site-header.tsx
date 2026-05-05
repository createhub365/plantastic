"use client";

import NextLink from "next/link";
import { motion, useReducedMotion } from "framer-motion";
import { ShoppingCart } from "@phosphor-icons/react/dist/csr/ShoppingCart";
import { PlantasticLogo } from "@/components/plantastic-logo";
import { PhosphorIcon } from "@/components/phosphor-icon";
import { colors } from "@/lib/theme/colors";
import { useCart } from "@/lib/cart/cart-context";

const MotionLink = motion.create(NextLink);

export function SiteHeader() {
  const cart = useCart();
  const reduce = useReducedMotion();

  return (
    <motion.header
      className="sticky top-0 z-40 border-b backdrop-blur-md"
      style={{
        borderColor: colors.border,
        backgroundColor: "rgba(249,251,249,0.92)",
      }}
      initial={reduce ? false : { y: -8, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
    >
      <div className="mx-auto flex h-[56px] w-full max-w-6xl items-center justify-between gap-4 px-4 sm:h-[60px] sm:px-6">
        <PlantasticLogo reduceMotion={reduce} />

        <div className="flex items-center gap-2">
          <MotionLink
            href="/cart"
            className="relative inline-flex items-center justify-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-semibold shadow-sm"
            style={{
              borderColor: colors.border,
              backgroundColor: colors.card,
              color: colors.primary,
            }}
            whileHover={
              reduce ? undefined : { y: -2, boxShadow: "0 8px 20px rgba(46,125,50,0.15)" }
            }
            whileTap={reduce ? undefined : { scale: 0.97 }}
          >
            <PhosphorIcon
              icon={ShoppingCart}
              size="md"
              weight="bold"
              color={colors.primary}
            />
            Cart
            {cart.itemCount > 0 ? (
              <motion.span
                className="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full px-[5px] text-[11px] font-bold text-white"
                style={{ backgroundColor: colors.primary }}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 560, damping: 18 }}
              >
                {cart.itemCount > 99 ? "99+" : cart.itemCount}
              </motion.span>
            ) : null}
          </MotionLink>
        </div>
      </div>
    </motion.header>
  );
}
