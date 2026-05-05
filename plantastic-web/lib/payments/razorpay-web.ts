"use client";

import { normalizeIndianMobile } from "@/lib/cart/delivery-address";

declare global {
  interface Window {
    Razorpay?: new (opts: RazorpayOptions) => RazorpayInstance;
  }
}

type RazorpayOptions = Record<string, unknown>;

type RazorpayInstance = {
  open(): void;
  on(event: string, handler: (payload: unknown) => void): void;
};

export type RazorpaySuccessPayload = {
  razorpay_payment_id?: string;
  razorpay_order_id?: string;
  razorpay_signature?: string;
};

export function loadRazorpayCheckoutScript(): Promise<void> {
  if (typeof window === "undefined") {
    return Promise.reject(new Error("Window missing"));
  }
  if (window.Razorpay) return Promise.resolve();

  return new Promise((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(
      'script[src="https://checkout.razorpay.com/v1/checkout.js"]',
    );
    if (existing) {
      existing.addEventListener("load", () => resolve(), { once: true });
      existing.addEventListener(
        "error",
        () => reject(new Error("checkout.js failed to load")),
        { once: true },
      );
      return;
    }
    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("checkout.js failed to load"));
    document.head.appendChild(script);
  });
}

/** Wait briefly for Razorpay global after script load */
export async function ensureRazorpay(): Promise<(typeof window)["Razorpay"]> {
  await loadRazorpayCheckoutScript();
  for (let i = 0; i < 80; i++) {
    const Rzp = typeof window !== "undefined" ? window.Razorpay : undefined;
    if (Rzp) return Rzp;
    await new Promise((r) => setTimeout(r, 40));
  }
  throw new Error("Razorpay is unavailable");
}

export type RazorpayOpenResult =
  | { ok: true; payload: RazorpaySuccessPayload }
  | { ok: false; reason: "dismissed" | "failed"; message?: string };

export async function presentRazorpayCheckout(opts: {
  keyId: string;
  /** Amount in INR paise — must match the server order amount */
  amountPaise: number;
  /** Razorpay `order_*` from create-order API */
  orderId: string;
  /** Passed to Razorpay prefill */
  customerName?: string;
  customerPhone?: string;
}): Promise<RazorpayOpenResult> {
  const Rz = await ensureRazorpay();
  const RzpCtor = Rz!;

  const namePre = `${opts.customerName ?? ""}`.trim();
  const phonePre = normalizeIndianMobile(opts.customerPhone ?? "");
  const prefill: Record<string, string> = {};
  if (namePre) prefill.name = namePre;
  if (phonePre.length === 10) prefill.contact = phonePre;

  return new Promise<RazorpayOpenResult>((resolve) => {
    let settled = false;
    function finish(result: RazorpayOpenResult) {
      if (settled) return;
      settled = true;
      resolve(result);
    }

    const instance = new RzpCtor({
      key: opts.keyId,
      amount: opts.amountPaise,
      currency: "INR",
      name: "Plantastic",
      description: "Plant order",
      order_id: opts.orderId,
      theme: { color: "#2E7D32" },
      prefill,
      handler(response: RazorpaySuccessPayload | Record<string, unknown>) {
        const r = response as RazorpaySuccessPayload;
        finish({
          ok: true,
          payload: {
            razorpay_payment_id: `${r?.razorpay_payment_id ?? ""}`.trim() || undefined,
            razorpay_order_id: `${r?.razorpay_order_id ?? ""}`.trim() || undefined,
            razorpay_signature: `${r?.razorpay_signature ?? ""}`.trim() || undefined,
          },
        });
      },
      modal: {
        ondismiss() {
          finish({ ok: false, reason: "dismissed" });
        },
      },
    });

    instance.on("payment.failed", (payload: unknown) => {
      let message = "Payment failed";
      if (payload && typeof payload === "object") {
        const err = (payload as { error?: { description?: string } }).error;
        if (err?.description) message = err.description;
      }
      finish({ ok: false, reason: "failed", message });
    });

    instance.open();
  });
}
