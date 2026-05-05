"use client";

import NextLink from "next/link";
import { useEffect, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";
import { CheckCircle } from "@phosphor-icons/react/dist/csr/CheckCircle";
import { PhosphorIcon } from "@/components/phosphor-icon";
import {
  type LastCheckoutSnapshot,
  readLastCheckout,
} from "@/lib/cart/last-checkout";
import { colors } from "@/lib/theme/colors";

const MotionLink = motion.create(NextLink);

export default function CheckoutSuccessPage() {
  const reduce = useReducedMotion();
  const [snap, setSnap] = useState<LastCheckoutSnapshot | null | undefined>(
    undefined,
  );

  useEffect(() => {
    setSnap(readLastCheckout());
  }, []);

  if (snap === undefined) {
    return (
      <div
        className="mx-auto w-full max-w-lg px-4 py-16 text-center sm:px-6"
        style={{ color: colors.textSecondary }}
      >
        Loading…
      </div>
    );
  }

  if (snap === null) {
    return (
      <motion.div
        className="mx-auto w-full max-w-lg space-y-4 px-4 py-16 text-center sm:px-6"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <h1
          className="text-xl font-semibold tracking-tight"
          style={{ color: colors.textPrimary }}
        >
          No order found
        </h1>
        <p className="text-sm" style={{ color: colors.textSecondary }}>
          Open this page right after checkout, or return to the shop.
        </p>
        <MotionLink
          href="/"
          className="inline-flex items-center justify-center rounded-full px-6 py-2.5 text-sm font-semibold text-white"
          style={{ backgroundColor: colors.primary }}
          whileHover={reduce ? undefined : { scale: 1.02 }}
        >
          Back to shop
        </MotionLink>
      </motion.div>
    );
  }

  const placed = new Date(snap.placedAt);
  const dateLabel = Number.isFinite(placed.getTime())
    ? placed.toLocaleString("en-IN", {
        dateStyle: "medium",
        timeStyle: "short",
      })
    : snap.placedAt;

  return (
    <motion.div
      className="mx-auto w-full max-w-lg space-y-6 px-4 py-10 sm:px-6 sm:py-14"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
    >
      <div className="text-center">
        <div
          className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full"
          style={{ backgroundColor: `${colors.primary}18` }}
          aria-hidden
        >
          <PhosphorIcon
            icon={CheckCircle}
            size="2xl"
            weight="fill"
            color={colors.primary}
          />
        </div>
        <h1
          className="text-2xl font-bold tracking-tight"
          style={{ color: colors.textPrimary }}
        >
          Order placed
        </h1>
        <p className="mt-2 text-sm" style={{ color: colors.textSecondary }}>
          Thank you — we&apos;ve received your order.
        </p>
        <div className="mt-2 space-y-0.5">
          <p
            className="font-mono text-xs font-semibold tracking-wide"
            style={{ color: colors.primary }}
          >
            #{snap.orderId.toUpperCase()}
          </p>
          {snap.paidWithRazorpay &&
          (snap.razorpayPaymentId || snap.razorpayOrderId) ? (
            <p className="text-[11px]" style={{ color: colors.textSecondary }}>
              Razorpay
              {snap.razorpayPaymentId ? (
                <>
                  {" "}
                  · Pay{" "}
                  <span
                    className="font-mono font-semibold"
                    style={{ color: colors.textPrimary }}
                  >
                    {snap.razorpayPaymentId}
                  </span>
                </>
              ) : null}
            </p>
          ) : null}
        </div>
        <p className="mt-1 text-xs" style={{ color: colors.textSecondary }}>
          {dateLabel}
        </p>
      </div>

      {snap.delivery ? (
        <div
          className="rounded-2xl border p-4 text-left text-sm"
          style={{ borderColor: colors.border, backgroundColor: colors.card }}
        >
          <div
            className="text-xs font-extrabold uppercase tracking-wide"
            style={{ color: colors.primary }}
          >
            Deliver to
          </div>
          <p
            className="mt-2 font-semibold leading-snug"
            style={{ color: colors.textPrimary }}
          >
            {snap.delivery.customerName}
          </p>
          <p style={{ color: colors.textSecondary }} className="mt-1">
            {snap.delivery.addressLine1}
            <br />
            {snap.delivery.city}, {snap.delivery.postalCode}
          </p>
          <p className="mt-2 text-xs font-semibold" style={{ color: colors.textSecondary }}>
            Phone · +91 {snap.delivery.phone}
          </p>
        </div>
      ) : null}

      <div
        className="rounded-2xl border p-4 text-left"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <div
          className="text-xs font-extrabold uppercase tracking-wide"
          style={{ color: colors.primary }}
        >
          Summary
        </div>
        <ul className="mt-3 space-y-2.5 text-sm">
          {snap.lines.map((line) => (
            <li
              key={`${line.productId}:${line.lineId}`}
              className="flex justify-between gap-3 border-b border-dashed pb-2 last:border-0 last:pb-0"
              style={{ borderColor: colors.border }}
            >
              <span className="min-w-0" style={{ color: colors.textPrimary }}>
                <span className="font-semibold">{line.productTitle}</span>
                <span className="block text-xs" style={{ color: colors.textSecondary }}>
                  {line.kitLabel} × {line.qty}
                </span>
              </span>
              <span
                className="shrink-0 font-semibold tabular-nums"
                style={{ color: colors.textPrimary }}
              >
                ₹{(line.qty * line.priceInr).toLocaleString("en-IN")}
              </span>
            </li>
          ))}
        </ul>
        <div
          className="mt-4 flex items-center justify-between border-t pt-3 text-base font-bold"
          style={{ borderColor: colors.border, color: colors.textPrimary }}
        >
          <span>Total</span>
          <span className="tabular-nums">
            ₹{snap.subtotalInr.toLocaleString("en-IN")}
          </span>
        </div>
      </div>

      <p className="text-center text-xs leading-relaxed" style={{ color: colors.textSecondary }}>
        {snap.paidWithRazorpay
          ? "Payment confirmed via Razorpay. We'll follow up by email where configured."
          : "This checkout was recorded without live payment."}
      </p>

      <div className="flex flex-col gap-2 sm:flex-row sm:justify-center">
        <MotionLink
          href="/"
          className="inline-flex flex-1 items-center justify-center rounded-full px-5 py-2.5 text-sm font-semibold text-white sm:flex-none sm:min-w-[160px]"
          style={{ backgroundColor: colors.primary }}
          whileHover={reduce ? undefined : { scale: 1.02 }}
        >
          Continue shopping
        </MotionLink>
      </div>
    </motion.div>
  );
}
