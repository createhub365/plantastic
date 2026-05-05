import { NextResponse } from "next/server";

/**
 * Razorpay `key_id` is safe for the browser. Prefer `NEXT_PUBLIC_RAZORPAY_KEY_ID`;
 * falls back to `RAZORPAY_KEY_ID` so one env var matches Flutter tooling.
 */
export async function GET() {
  const keyId = (
    process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID ??
    process.env.RAZORPAY_KEY_ID ??
    ""
  ).trim();

  return NextResponse.json({
    keyId: keyId || null,
  });
}
