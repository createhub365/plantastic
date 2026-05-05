import { NextResponse } from "next/server";
import { invokeSupabaseEdgeFunction } from "@/lib/payments/invoke-edge-fn";

/** Server proxy to Supabase `razorpay-create-order` (keeps Razorpay secret off the client). */
export async function POST(req: Request) {
  let body: { amount_paise?: number };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const raw = body.amount_paise;
  if (typeof raw !== "number" || !Number.isFinite(raw)) {
    return NextResponse.json({ error: "Invalid amount_paise" }, { status: 400 });
  }
  const amountInt = Math.round(raw);
  if (amountInt < 100) {
    return NextResponse.json(
      { error: "Minimum amount is ₹1 (100 paise)" },
      { status: 400 },
    );
  }

  const { ok, status, data } = await invokeSupabaseEdgeFunction(
    "razorpay-create-order",
    { amount_paise: amountInt },
  );

  const row =
    typeof data === "object" && data !== null
      ? (data as Record<string, unknown>)
      : {};

  if (!ok) {
    const err =
      typeof row.error === "string" ? row.error : "Could not create order";
    return NextResponse.json(
      { error: err },
      { status: status >= 400 && status < 600 ? status : 502 },
    );
  }

  const orderId = typeof row.order_id === "string" ? row.order_id.trim() : "";
  if (!orderId) {
    return NextResponse.json({ error: "Unexpected response" }, { status: 502 });
  }

  return NextResponse.json({
    order_id: orderId,
    amount_paise: row.amount_paise ?? amountInt,
    currency: row.currency ?? "INR",
  });
}
