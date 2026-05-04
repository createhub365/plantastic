import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const keyId = Deno.env.get("RAZORPAY_KEY_ID");
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");
  if (!keyId?.trim() || !keySecret?.trim()) {
    return json({ error: "Razorpay keys missing on server (set secrets)" }, 500);
  }

  let body: { amount_paise?: number };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const raw = body.amount_paise;
  if (typeof raw !== "number" || !Number.isFinite(raw)) {
    return json({ error: "Invalid amount_paise" }, 400);
  }
  const amountInt = Math.round(raw);
  // 100 paise (1 INR) minimum; 50_000_000 paise (5L INR) maximum per order
  if (amountInt < 100 || amountInt > 50_000_000) {
    return json({ error: "amount_paise out of range" }, 400);
  }

  const auth = btoa(`${keyId.trim()}:${keySecret.trim()}`);
  const res = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amountInt,
      currency: "INR",
      receipt: `pf_${crypto.randomUUID().replaceAll("-", "").slice(0, 14)}`,
    }),
  });

  const data = (await res.json()) as Record<string, unknown>;
  if (!res.ok) {
    const desc =
      (data?.error as Record<string, unknown> | undefined)?.description;
    console.error("Razorpay orders API error", data);
    return json(
      { error: typeof desc === "string" ? desc : "Razorpay order failed" },
      502,
    );
  }

  const orderId = data.id;
  if (typeof orderId !== "string" || !orderId.trim()) {
    return json({ error: "Unexpected Razorpay response" }, 502);
  }

  return json({
    order_id: orderId,
    amount_paise: data.amount,
    currency: data.currency ?? "INR",
  });
});
