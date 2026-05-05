import { NextResponse } from "next/server";
import type { DeliveryAddress } from "@/lib/cart/delivery-address";
import {
  normalizeIndianMobile,
  validateDeliveryForCheckout,
} from "@/lib/cart/delivery-address";
import { restInsert } from "@/lib/supabase/rest";

type OrderLineInput = {
  productId: string;
  title: string;
  kit_line_id: string;
  kit_label: string;
  unitPrice: number;
  qty: number;
};

function parseLines(raw: unknown): OrderLineInput[] | null {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  const out: OrderLineInput[] = [];
  for (const row of raw) {
    if (!row || typeof row !== "object") continue;
    const r = row as Record<string, unknown>;
    const productId = `${r.productId ?? ""}`.trim();
    const kit_line_id = `${r.kit_line_id ?? ""}`.trim();
    if (!productId || !kit_line_id) continue;
    const title = `${r.title ?? ""}`.trim() || productId;
    const kit_label = `${r.kit_label ?? ""}`.trim() || "Kit";
    const unitPrice = Number(r.unitPrice ?? NaN);
    const qtyRaw = Number(r.qty ?? NaN);
    if (!Number.isFinite(unitPrice) || unitPrice < 0) continue;
    if (!Number.isFinite(qtyRaw)) continue;
    const qty = Math.max(1, Math.floor(qtyRaw));
    out.push({ productId, title, kit_line_id, kit_label, unitPrice, qty });
  }
  return out.length > 0 ? out : null;
}

/** Guest insert into `orders` — same payload shape as Flutter `OrderService.placeOrder`. */
export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const addr: DeliveryAddress = {
    customerName: `${body.customer_name ?? ""}`,
    phone: `${body.phone ?? ""}`,
    addressLine1: `${body.address_line1 ?? ""}`,
    city: `${body.city ?? ""}`,
    postalCode: `${body.postal_code ?? ""}`,
  };

  const addrErr = validateDeliveryForCheckout(addr);
  if (addrErr) {
    return NextResponse.json({ error: addrErr }, { status: 400 });
  }

  const linesIn = parseLines(body.items);
  if (!linesIn) {
    return NextResponse.json({ error: "Invalid items" }, { status: 400 });
  }

  let sum = 0;
  const items = linesIn.map((line) => {
    sum += line.qty * line.unitPrice;
    return {
      productId: line.productId,
      title: line.title,
      kit_line_id: line.kit_line_id,
      kit_label: line.kit_label,
      kit: line.kit_label,
      unitPrice: line.unitPrice,
      qty: line.qty,
    };
  });

  const clientTotal = Number(body.total ?? NaN);
  if (!Number.isFinite(clientTotal) || Math.round(clientTotal) !== sum) {
    return NextResponse.json({ error: "Total does not match items" }, { status: 400 });
  }

  const phoneStored = normalizeIndianMobile(addr.phone);
  const payId = `${body.razorpay_payment_id ?? ""}`.trim();
  const oid = `${body.razorpay_order_id ?? ""}`.trim();
  const sig = `${body.razorpay_signature ?? ""}`.trim();

  const row: Record<string, unknown> = {
    customer_name: addr.customerName.trim(),
    phone: phoneStored,
    address_line1: addr.addressLine1.trim(),
    city: addr.city.trim(),
    postal_code: addr.postalCode.replace(/\D/g, "").slice(0, 6),
    items,
    total: sum,
  };
  if (payId) row.razorpay_payment_id = payId;
  if (oid) row.razorpay_order_id = oid;
  if (sig) row.razorpay_signature = sig;

  const { ok, status, bodyText } = await restInsert("orders", row);
  if (!ok) {
    const short =
      bodyText.length > 220 ? `${bodyText.slice(0, 217)}…` : bodyText;
    return NextResponse.json(
      { error: short || `Insert failed (${status})` },
      { status: status >= 400 && status < 600 ? status : 502 },
    );
  }

  return NextResponse.json({ ok: true });
}
