/** Minimal `orders` row for admin (matches Flutter `ShopOrder.fromMap`). */

export type ShopOrderRow = {
  id: string;
  createdAt: string | null;
  customerName: string;
  phone: string;
  addressLine1: string;
  city: string;
  postalCode: string;
  total: number;
  status: string;
  rawItems: Record<string, unknown>[];
  razorpayPaymentId: string | null;
  razorpayOrderId: string | null;
};

export function parseShopOrderRow(
  row: Record<string, unknown>,
): ShopOrderRow {
  const itemsDyn = row["items"];
  const rawItems: Record<string, unknown>[] = [];
  if (Array.isArray(itemsDyn)) {
    for (const e of itemsDyn) {
      if (e && typeof e === "object") rawItems.push(e as Record<string, unknown>);
    }
  }

  let createdAt: string | null = null;
  const rawAt = row["created_at"];
  if (typeof rawAt === "string") createdAt = rawAt;

  const rawStatus = row["status"] ?? row["fulfillment_status"];
  const statusStr =
    rawStatus == null ? "pending" : `${rawStatus}`.trim().toLowerCase();

  const rpPay = row["razorpay_payment_id"];
  const rpOrd = row["razorpay_order_id"];

  const totalRaw = row["total"];
  const total =
    typeof totalRaw === "number"
      ? totalRaw
      : Number.parseFloat(`${totalRaw ?? 0}`) || 0;

  return {
    id: row["id"] == null ? "" : `${row.id}`,
    createdAt,
    customerName: `${row["customer_name"] ?? ""}`,
    phone: `${row["phone"] ?? ""}`,
    addressLine1: `${row["address_line1"] ?? ""}`,
    city: `${row["city"] ?? ""}`,
    postalCode: `${row["postal_code"] ?? ""}`,
    total,
    status: statusStr.length === 0 ? "pending" : statusStr,
    rawItems,
    razorpayPaymentId: rpPay == null ? null : `${rpPay}`.trim(),
    razorpayOrderId: rpOrd == null ? null : `${rpOrd}`.trim(),
  };
}
