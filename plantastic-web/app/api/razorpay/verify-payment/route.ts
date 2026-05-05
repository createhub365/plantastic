import { NextResponse } from "next/server";
import { invokeSupabaseEdgeFunction } from "@/lib/payments/invoke-edge-fn";

export async function POST(req: Request) {
  let body: {
    razorpay_order_id?: string;
    razorpay_payment_id?: string;
    razorpay_signature?: string;
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ valid: false, error: "Invalid JSON" }, { status: 400 });
  }

  const orderId = body.razorpay_order_id?.trim();
  const paymentId = body.razorpay_payment_id?.trim();
  const signature = body.razorpay_signature?.trim();
  if (!orderId || !paymentId || !signature) {
    return NextResponse.json({ valid: false, error: "Missing fields" }, { status: 400 });
  }

  const { ok, status, data } = await invokeSupabaseEdgeFunction(
    "razorpay-verify-payment",
    {
      razorpay_order_id: orderId,
      razorpay_payment_id: paymentId,
      razorpay_signature: signature,
    },
  );

  if (!ok || typeof data !== "object" || data === null) {
    const err =
      typeof (data as { error?: unknown }).error === "string"
        ? (data as { error: string }).error
        : "Verification failed";
    return NextResponse.json(
      { valid: false, error: err },
      { status: status >= 400 ? status : 502 },
    );
  }

  const valid = (data as { valid?: unknown }).valid === true;
  return NextResponse.json({ valid });
}
