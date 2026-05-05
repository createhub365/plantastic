"use client";

import { useRouter } from "next/navigation";
import { startTransition, useState } from "react";
import { adminUpdateOrderStatus } from "@/lib/admin/catalog-actions";
import type { ShopOrderRow } from "@/lib/catalog/parse-shop-order";
import { colors } from "@/lib/theme/colors";

function shortId(id: string) {
  const t = id.trim();
  if (t.length <= 10) return t;
  return `${t.slice(0, 8)}…`;
}

function fmtDate(iso: string | null): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return `${d.toLocaleDateString()} ${d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
}

const statuses = ["pending", "shipped", "delivered"] as const;

function labelStatus(s: string) {
  if (s === "shipped") return "Shipped";
  if (s === "delivered") return "Delivered";
  return "Pending";
}

export function AdminOrdersPanel({ orders }: { orders: ShopOrderRow[] }) {
  const router = useRouter();
  const [msg, setMsg] = useState<string | null>(null);

  const setStatus = (id: string, status: string) => {
    setMsg(null);
    startTransition(() => {
      void adminUpdateOrderStatus(id, status).then((r) => {
        if (r.error) setMsg(r.error);
        router.refresh();
      });
    });
  };

  return (
    <div className="space-y-4">
      {msg ? <p className="text-sm text-red-600">{msg}</p> : null}

      {orders.length === 0 ? (
        <p className="rounded-xl border px-6 py-12 text-center text-sm" style={{ borderColor: colors.border }}>
          No orders yet. When shoppers check out, rows appear here.
        </p>
      ) : (
        <div className="space-y-3">
          {orders.map((o) => (
            <details
              key={o.id}
              className="overflow-hidden rounded-xl border"
              style={{ borderColor: colors.border, backgroundColor: colors.card }}
            >
              <summary className="flex cursor-pointer list-none flex-wrap items-center gap-3 px-4 py-3">
                <span className="font-bold">#{shortId(o.id)}</span>
                <span className="tabular-nums">₹{o.total}</span>
                <span className="text-xs uppercase" style={{ color: colors.textSecondary }}>
                  {labelStatus(o.status)}
                </span>
                <span className="text-xs" style={{ color: colors.textSecondary }}>
                  {fmtDate(o.createdAt)} · {o.customerName}
                </span>
                <span className="ml-auto" onClick={(e) => e.stopPropagation()}>
                  <select
                    aria-label={`Status for ${o.id}`}
                    className="rounded-lg border px-2 py-1 text-sm"
                    style={{ borderColor: colors.border }}
                    value={
                      statuses.includes(o.status as (typeof statuses)[number])
                        ? o.status
                        : "pending"
                    }
                    onChange={(e) => setStatus(o.id, e.target.value)}
                  >
                    {statuses.map((s) => (
                      <option key={s} value={s}>
                        {labelStatus(s)}
                      </option>
                    ))}
                  </select>
                </span>
              </summary>
              <div
                className="space-y-2 border-t px-4 py-3 text-sm"
                style={{ borderColor: colors.border }}
              >
                <p>
                  <span className="font-semibold">Phone:</span> {o.phone || "—"}
                </p>
                <p>
                  <span className="font-semibold">Ship to:</span> {o.addressLine1}, {o.city}{" "}
                  {o.postalCode}
                </p>
                {o.razorpayPaymentId ? (
                  <p className="font-mono text-xs">Razorpay: {o.razorpayPaymentId}</p>
                ) : null}
                <div>
                  <div className="font-semibold">Items</div>
                  <ul className="mt-1 list-inside list-disc text-xs font-mono text-neutral-600">
                    {o.rawItems.slice(0, 12).map((it, idx) => (
                      <li key={idx}>{JSON.stringify(it)}</li>
                    ))}
                  </ul>
                </div>
              </div>
            </details>
          ))}
        </div>
      )}
    </div>
  );
}
