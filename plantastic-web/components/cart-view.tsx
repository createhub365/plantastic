"use client";

import NextLink from "next/link";
import { useRouter } from "next/navigation";
import {
  AnimatePresence,
  motion,
  useReducedMotion,
} from "framer-motion";
import { useEffect, useMemo, useState } from "react";
import { Minus } from "@phosphor-icons/react/dist/csr/Minus";
import { Plus } from "@phosphor-icons/react/dist/csr/Plus";
import { ShoppingBagOpen } from "@phosphor-icons/react/dist/csr/ShoppingBagOpen";
import { Trash } from "@phosphor-icons/react/dist/csr/Trash";
import { PhosphorIcon } from "@/components/phosphor-icon";
import { useCart } from "@/lib/cart/cart-context";
import { saveLastCheckout } from "@/lib/cart/last-checkout";
import { presentRazorpayCheckout } from "@/lib/payments/razorpay-web";
import {
  EMPTY_DELIVERY_ADDRESS,
  loadDeliveryDraft,
  normalizeIndianMobile,
  saveDeliveryDraft,
  validateDeliveryForCheckout,
  type DeliveryAddress,
} from "@/lib/cart/delivery-address";
import { colors } from "@/lib/theme/colors";

const MotionLink = motion.create(NextLink);

export function CartView() {
  const cart = useCart();
  const router = useRouter();
  const reduce = useReducedMotion();
  const [checkoutBusy, setCheckoutBusy] = useState(false);
  const [checkoutError, setCheckoutError] = useState<string | null>(null);
  const [delivery, setDelivery] =
    useState<DeliveryAddress>(EMPTY_DELIVERY_ADDRESS);

  useEffect(() => {
    const d = loadDeliveryDraft();
    if (d) setDelivery(d);
  }, []);

  useEffect(() => {
    const t = window.setTimeout(() => {
      const hasAny =
        delivery.customerName.trim().length > 0 ||
        delivery.phone.trim().length > 0 ||
        delivery.addressLine1.trim().length > 0 ||
        delivery.city.trim().length > 0 ||
        delivery.postalCode.trim().length > 0;
      if (hasAny) saveDeliveryDraft(delivery);
    }, 600);
    return () => window.clearTimeout(t);
  }, [delivery]);

  const lineVariants = useMemo(
    () => ({
      hidden: { opacity: 0, x: reduce ? 0 : -14 },
      show: {
        opacity: 1,
        x: 0,
        transition: { type: "spring" as const, stiffness: 380, damping: 26 },
      },
      exit: {
        opacity: 0,
        scale: reduce ? 1 : 0.94,
        transition: { duration: reduce ? 0.15 : 0.22 },
      },
    }),
    [reduce],
  );

  if (cart.lines.length === 0) {
    return (
      <motion.div
        className="mx-auto flex w-full max-w-lg flex-col items-center px-4 py-16 text-center sm:px-6 sm:py-20"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div
          className="mb-6 flex h-[88px] w-[88px] shrink-0 items-center justify-center rounded-full sm:h-[100px] sm:w-[100px]"
          style={{
            backgroundColor: `${colors.primary}14`,
            border: `1px dashed ${colors.primary}40`,
          }}
          aria-hidden
        >
          <ShoppingBagOpen
            size={44}
            weight="duotone"
            color={colors.primary}
            className="sm:scale-110"
            aria-hidden
          />
        </div>
        <motion.h1
          className="text-xl font-semibold tracking-tight sm:text-2xl"
          style={{ color: colors.textPrimary }}
        >
          Your cart is empty
        </motion.h1>
        <p className="mt-2 max-w-sm text-sm" style={{ color: colors.textSecondary }}>
          Add a kit from the shop to get started.
        </p>
        <motion.div className="mt-8 w-full max-w-xs">
          <MotionLink
            href="/"
            className="inline-flex w-full items-center justify-center rounded-full px-5 py-2.5 text-sm font-semibold text-white"
            style={{ backgroundColor: colors.primary }}
            whileHover={reduce ? undefined : { scale: 1.02 }}
            whileTap={reduce ? undefined : { scale: 0.98 }}
          >
            Continue shopping
          </MotionLink>
        </motion.div>
      </motion.div>
    );
  }

  return (
    <motion.div
      className="mx-auto w-full max-w-2xl space-y-4 px-4 py-8 sm:px-6 sm:py-10"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
    >
      <div className="flex items-end justify-between gap-4">
        <div>
          <motion.h1
            className="text-xl font-semibold tracking-tight sm:text-2xl"
            style={{ color: colors.textPrimary }}
          >
            Cart
          </motion.h1>
          <p className="mt-1 text-sm" style={{ color: colors.textSecondary }}>
            Fill in where to ship, then pay with Razorpay. Your order row is saved
            in Supabase after payment verifies (same as the Flutter app).
          </p>
        </div>
        <motion.button
          type="button"
          onClick={() => cart.clear()}
          className="text-xs font-semibold underline-offset-4 hover:underline"
          style={{ color: colors.textSecondary }}
          whileHover={reduce ? undefined : { scale: 1.06 }}
          whileTap={reduce ? undefined : { scale: 0.94 }}
        >
          Clear
        </motion.button>
      </div>

      <div className="space-y-3">
        <AnimatePresence mode="popLayout">
          {cart.lines.map((line) => (
            <motion.div
              key={`${line.productId}:${line.lineId}`}
              layout
              variants={lineVariants}
              initial="hidden"
              animate="show"
              exit="exit"
              className="overflow-hidden rounded-2xl border p-4"
              style={{
                borderColor: colors.border,
                backgroundColor: colors.card,
              }}
            >
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="min-w-0">
                  <div
                    className="truncate font-semibold"
                    style={{ color: colors.textPrimary }}
                  >
                    {line.productTitle}
                  </div>
                  <div className="text-sm" style={{ color: colors.textSecondary }}>
                    {line.kitLabel} · ₹{line.priceInr.toLocaleString("en-IN")} each
                  </div>
                </div>

                <div className="flex flex-wrap items-center justify-end gap-2">
                  <motion.button
                    type="button"
                    className="inline-flex h-9 w-9 items-center justify-center rounded-full border"
                    style={{ borderColor: colors.border }}
                    aria-label="Decrease quantity"
                    whileTap={reduce ? undefined : { scale: 0.9 }}
                    onClick={() =>
                      cart.setQty(line.productId, line.lineId, line.qty - 1)
                    }
                  >
                    <PhosphorIcon
                      icon={Minus}
                      size="md"
                      weight="bold"
                      color={colors.textPrimary}
                    />
                  </motion.button>
                  <motion.span
                    className="w-8 text-center text-sm font-semibold"
                    key={`${line.productId}:${line.lineId}:${line.qty}`}
                    initial={{ scale: 0.92 }}
                    animate={{ scale: 1 }}
                  >
                    {line.qty}
                  </motion.span>
                  <motion.button
                    type="button"
                    className="inline-flex h-9 w-9 items-center justify-center rounded-full border"
                    style={{ borderColor: colors.border }}
                    aria-label="Increase quantity"
                    whileTap={reduce ? undefined : { scale: 0.9 }}
                    onClick={() =>
                      cart.setQty(line.productId, line.lineId, line.qty + 1)
                    }
                  >
                    <PhosphorIcon
                      icon={Plus}
                      size="md"
                      weight="bold"
                      color={colors.textPrimary}
                    />
                  </motion.button>
                  <motion.button
                    type="button"
                    className="inline-flex h-9 w-9 items-center justify-center rounded-full"
                    style={{ color: colors.textSecondary }}
                    aria-label="Remove line from cart"
                    title="Remove"
                    whileTap={reduce ? undefined : { scale: 0.9 }}
                    onClick={() =>
                      cart.remove(line.productId, line.lineId)
                    }
                  >
                    <PhosphorIcon
                      icon={Trash}
                      size="md"
                      weight="regular"
                      color={colors.textSecondary}
                    />
                  </motion.button>
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      <motion.div
        className="flex flex-col gap-3 rounded-2xl border p-4 sm:flex-row sm:items-center sm:justify-between"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
        layout
      >
        <div className="text-sm" style={{ color: colors.textSecondary }}>
          Subtotal
        </div>
        <motion.div
          className="text-lg font-semibold"
          style={{ color: colors.textPrimary }}
          key={`sub-${cart.subtotalInr}`}
          initial={{ scale: 1.06 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 500, damping: 18 }}
        >
          ₹{cart.subtotalInr.toLocaleString("en-IN")}
        </motion.div>
      </motion.div>

      <motion.div
        className="space-y-3 rounded-2xl border p-4"
        layout
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <div
          className="text-sm font-bold tracking-wide"
          style={{ color: colors.primary }}
        >
          Delivery details
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <label className="block sm:col-span-2">
            <span className="mb-1 block text-[11px] font-semibold uppercase tracking-wide opacity-75">
              Full name
            </span>
            <input
              className="w-full rounded-xl border px-3 py-2 text-sm outline-none ring-green-900/15 focus-visible:ring-2"
              style={{ borderColor: colors.border, color: colors.textPrimary }}
              autoComplete="name"
              value={delivery.customerName}
              onChange={(e) =>
                setDelivery((d) => ({ ...d, customerName: e.target.value }))
              }
            />
          </label>
          <label className="block">
            <span className="mb-1 block text-[11px] font-semibold uppercase tracking-wide opacity-75">
              Mobile
            </span>
            <input
              type="tel"
              inputMode="numeric"
              className="w-full rounded-xl border px-3 py-2 text-sm outline-none ring-green-900/15 focus-visible:ring-2"
              style={{ borderColor: colors.border, color: colors.textPrimary }}
              autoComplete="tel"
              placeholder="10-digit number"
              value={delivery.phone}
              onChange={(e) =>
                setDelivery((d) => ({ ...d, phone: e.target.value }))
              }
            />
          </label>
          <label className="block">
            <span className="mb-1 block text-[11px] font-semibold uppercase tracking-wide opacity-75">
              PIN code
            </span>
            <input
              type="tel"
              inputMode="numeric"
              className="w-full rounded-xl border px-3 py-2 text-sm outline-none ring-green-900/15 focus-visible:ring-2"
              style={{ borderColor: colors.border, color: colors.textPrimary }}
              autoComplete="postal-code"
              placeholder="6 digits"
              maxLength={8}
              value={delivery.postalCode}
              onChange={(e) =>
                setDelivery((d) => ({ ...d, postalCode: e.target.value }))
              }
            />
          </label>
          <label className="block sm:col-span-2">
            <span className="mb-1 block text-[11px] font-semibold uppercase tracking-wide opacity-75">
              Address
            </span>
            <input
              className="w-full rounded-xl border px-3 py-2 text-sm outline-none ring-green-900/15 focus-visible:ring-2"
              style={{ borderColor: colors.border, color: colors.textPrimary }}
              autoComplete="street-address"
              placeholder="House / street / landmark"
              value={delivery.addressLine1}
              onChange={(e) =>
                setDelivery((d) => ({ ...d, addressLine1: e.target.value }))
              }
            />
          </label>
          <label className="block sm:col-span-2">
            <span className="mb-1 block text-[11px] font-semibold uppercase tracking-wide opacity-75">
              City / town
            </span>
            <input
              className="w-full rounded-xl border px-3 py-2 text-sm outline-none ring-green-900/15 focus-visible:ring-2"
              style={{ borderColor: colors.border, color: colors.textPrimary }}
              autoComplete="address-level2"
              value={delivery.city}
              onChange={(e) =>
                setDelivery((d) => ({ ...d, city: e.target.value }))
              }
            />
          </label>
        </div>
      </motion.div>

      {checkoutError ? (
        <p
          className="rounded-xl border px-3 py-2 text-sm font-medium leading-snug"
          style={{
            borderColor: "#FFCDD2",
            backgroundColor: "#FFEBEE",
            color: "#B71C1C",
          }}
          role="alert"
        >
          {checkoutError}
        </p>
      ) : null}

      <div className="flex flex-col gap-2 sm:flex-row">
        <MotionLink
          href="/"
          className="inline-flex flex-1 items-center justify-center rounded-full border px-5 py-2.5 text-sm font-semibold"
          style={{ borderColor: colors.border, color: colors.textPrimary }}
          whileHover={reduce ? undefined : { scale: 1.02 }}
        >
          Continue shopping
        </MotionLink>
        <motion.button
          type="button"
          className="inline-flex flex-1 items-center justify-center rounded-full px-5 py-2.5 text-sm font-semibold text-white disabled:cursor-wait disabled:opacity-70"
          style={{ backgroundColor: colors.primary }}
          disabled={checkoutBusy}
          onClick={async () => {
            if (cart.lines.length === 0 || checkoutBusy) return;
            setCheckoutError(null);
            const v = validateDeliveryForCheckout(delivery);
            if (v) {
              setCheckoutError(v);
              return;
            }
            setCheckoutBusy(true);
            const linesSnapshot = cart.lines.map((l) => ({ ...l }));
            const subtotalInr = cart.subtotalInr;
            const deliverySaved: DeliveryAddress = {
              customerName: delivery.customerName.trim(),
              phone: normalizeIndianMobile(delivery.phone),
              addressLine1: delivery.addressLine1.trim(),
              city: delivery.city.trim(),
              postalCode: delivery.postalCode.replace(/\D/g, "").slice(0, 6),
            };

            try {
              const configRes = await fetch("/api/razorpay/public-config");
              const configJson = (await configRes.json()) as {
                keyId?: string | null;
              };
              const keyId = `${configJson.keyId ?? ""}`.trim();

              const amountPaise = Math.round(subtotalInr * 100);
              if (amountPaise < 100) {
                throw new Error("Minimum order is ₹1");
              }

              const orderRes = await fetch("/api/razorpay/create-order", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ amount_paise: amountPaise }),
              });
              const orderJson = (await orderRes.json()) as {
                order_id?: string;
                amount_paise?: unknown;
                error?: string;
              };

              if (!orderRes.ok || !orderJson.order_id) {
                throw new Error(
                  orderJson.error ??
                    "Could not start payment — check Supabase + Edge Functions",
                );
              }

              if (!keyId) {
                throw new Error(
                  "Razorpay key_id missing — set NEXT_PUBLIC_RAZORPAY_KEY_ID or RAZORPAY_KEY_ID in .env",
                );
              }

              const amt = Number(orderJson.amount_paise ?? amountPaise);
              const payAmount = Number.isFinite(amt) ? Math.round(amt) : amountPaise;

              const session = await presentRazorpayCheckout({
                keyId,
                amountPaise: payAmount,
                orderId: orderJson.order_id,
                customerName: deliverySaved.customerName,
                customerPhone: deliverySaved.phone,
              });

              if (!session.ok) {
                if (session.reason === "dismissed") {
                  setCheckoutBusy(false);
                  return;
                }
                throw new Error(session.message ?? "Payment failed");
              }

              const payload = session.payload;
              const pid = `${payload.razorpay_payment_id ?? ""}`.trim();
              const oid = `${payload.razorpay_order_id ?? ""}`.trim();
              const sig = `${payload.razorpay_signature ?? ""}`.trim();
              if (!pid || !oid || !sig) {
                throw new Error("Incomplete payment response from Razorpay");
              }

              const verifyRes = await fetch("/api/razorpay/verify-payment", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  razorpay_order_id: oid,
                  razorpay_payment_id: pid,
                  razorpay_signature: sig,
                }),
              });
              const verifyJson = (await verifyRes.json()) as {
                valid?: boolean;
                error?: string;
              };
              if (!verifyJson.valid) {
                throw new Error(
                  verifyJson.error ??
                    "Could not verify payment — contact support",
                );
              }

              const placeRes = await fetch("/api/orders/place", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  customer_name: deliverySaved.customerName,
                  phone: deliverySaved.phone,
                  address_line1: deliverySaved.addressLine1,
                  city: deliverySaved.city,
                  postal_code: deliverySaved.postalCode,
                  items: linesSnapshot.map((line) => ({
                    productId: line.productId,
                    title: line.productTitle,
                    kit_line_id: line.lineId,
                    kit_label: line.kitLabel,
                    kit: line.kitLabel,
                    unitPrice: line.priceInr,
                    qty: line.qty,
                  })),
                  total: subtotalInr,
                  razorpay_payment_id: pid,
                  razorpay_order_id: oid,
                  razorpay_signature: sig,
                }),
              });
              const placeJson = (await placeRes.json()) as { error?: string };
              if (!placeRes.ok) {
                throw new Error(
                  placeJson.error ??
                    `Payment succeeded (${pid}) but saving the order failed — contact support with this payment id.`,
                );
              }

              saveLastCheckout({
                orderId: pid,
                placedAt: new Date().toISOString(),
                lines: linesSnapshot,
                subtotalInr,
                delivery: deliverySaved,
                paidWithRazorpay: true,
                razorpayOrderId: oid,
                razorpayPaymentId: pid,
              });
              saveDeliveryDraft(delivery);
              cart.clear();
              router.push("/checkout/success");
            } catch (e) {
              const msg =
                e instanceof Error ? e.message : "Something went wrong. Try again.";
              setCheckoutError(msg);
              setCheckoutBusy(false);
            }
          }}
        >
          {checkoutBusy ? "Opening payment…" : "Pay & place order"}
        </motion.button>
      </div>
    </motion.div>
  );
}
