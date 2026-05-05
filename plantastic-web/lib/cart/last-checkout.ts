import type { CartLine } from "@/lib/cart/cart-context";
import type { DeliveryAddress } from "@/lib/cart/delivery-address";

export type LastCheckoutSnapshot = {
  orderId: string;
  placedAt: string;
  lines: CartLine[];
  subtotalInr: number;
  /** Delivery snapshot after successful checkout */
  delivery?: DeliveryAddress;
  /** Set when Razorpay completed + verified */
  paidWithRazorpay?: boolean;
  razorpayOrderId?: string;
  razorpayPaymentId?: string;
};

export const LAST_CHECKOUT_STORAGE_KEY = "plantastic.web.lastCheckout.v1";

export function saveLastCheckout(snapshot: LastCheckoutSnapshot): void {
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.setItem(
      LAST_CHECKOUT_STORAGE_KEY,
      JSON.stringify(snapshot),
    );
  } catch {
    /* quota / private mode */
  }
}

export function readLastCheckout(): LastCheckoutSnapshot | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.sessionStorage.getItem(LAST_CHECKOUT_STORAGE_KEY);
    if (!raw) return null;
    const data = JSON.parse(raw) as unknown;
    if (!data || typeof data !== "object") return null;
    const o = data as Record<string, unknown>;
    const orderId = `${o.orderId ?? ""}`.trim();
    const placedAt = `${o.placedAt ?? ""}`.trim();
    const subtotalInr = Number(o.subtotalInr ?? NaN);
    const linesRaw = o.lines;
    if (!orderId || !placedAt || !Number.isFinite(subtotalInr) || !Array.isArray(linesRaw)) {
      return null;
    }
    const lines: CartLine[] = [];
    for (const row of linesRaw) {
      if (!row || typeof row !== "object") continue;
      const r = row as Record<string, unknown>;
      const productId = `${r.productId ?? ""}`;
      const lineId = `${r.lineId ?? ""}`;
      if (!productId || !lineId) continue;
      lines.push({
        productId,
        productTitle: `${r.productTitle ?? ""}`,
        lineId,
        kitLabel: `${r.kitLabel ?? "Kit"}`,
        priceInr: Number(r.priceInr ?? 0) || 0,
        qty: Math.max(1, Math.floor(Number(r.qty ?? 1) || 1)),
      });
    }
    if (lines.length === 0) return null;
    const razorpayOrderIdRaw = `${o.razorpayOrderId ?? ""}`.trim();
    const razorpayPaymentIdRaw = `${o.razorpayPaymentId ?? ""}`.trim();
    const delRaw = o.delivery;
    let delivery: DeliveryAddress | undefined;
    if (delRaw && typeof delRaw === "object") {
      const d = delRaw as Record<string, unknown>;
      delivery = {
        customerName: `${d.customerName ?? ""}`.trim(),
        phone: `${d.phone ?? ""}`.trim(),
        addressLine1: `${d.addressLine1 ?? ""}`.trim(),
        city: `${d.city ?? ""}`.trim(),
        postalCode: `${d.postalCode ?? ""}`.trim(),
      };
      if (
        !delivery.customerName &&
        !delivery.phone &&
        !delivery.addressLine1 &&
        !delivery.city &&
        !delivery.postalCode
      ) {
        delivery = undefined;
      }
    }
    return {
      orderId,
      placedAt,
      lines,
      subtotalInr,
      ...(delivery ? { delivery } : {}),
      paidWithRazorpay: o.paidWithRazorpay === true,
      ...(razorpayOrderIdRaw ? { razorpayOrderId: razorpayOrderIdRaw } : {}),
      ...(razorpayPaymentIdRaw ? { razorpayPaymentId: razorpayPaymentIdRaw } : {}),
    };
  } catch {
    return null;
  }
}
