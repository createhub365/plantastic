export type DeliveryAddress = {
  customerName: string;
  phone: string;
  addressLine1: string;
  city: string;
  postalCode: string;
};

export const EMPTY_DELIVERY_ADDRESS: DeliveryAddress = {
  customerName: "",
  phone: "",
  addressLine1: "",
  city: "",
  postalCode: "",
};

const DRAFT_KEY = "plantastic.web.deliveryDraft.v1";

function stripDigits(value: string): string {
  return value.replace(/\D/g, "");
}

/** Last 10 digits for India mobiles from common inputs (+91..., 0-prefix). */
export function normalizeIndianMobile(value: string): string {
  let d = stripDigits(value.trim());
  if (d.length >= 12 && d.startsWith("91")) d = d.slice(-10);
  if (d.length === 11 && d.startsWith("0")) d = d.slice(1);
  return d;
}

export function loadDeliveryDraft(): DeliveryAddress | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(DRAFT_KEY);
    if (!raw) return null;
    const data = JSON.parse(raw) as unknown;
    if (!data || typeof data !== "object") return null;
    const o = data as Record<string, unknown>;
    return {
      customerName: `${o.customerName ?? ""}`.trim(),
      phone: `${o.phone ?? ""}`.trim(),
      addressLine1: `${o.addressLine1 ?? ""}`.trim(),
      city: `${o.city ?? ""}`.trim(),
      postalCode: `${o.postalCode ?? ""}`.trim(),
    };
  } catch {
    return null;
  }
}

export function saveDeliveryDraft(addr: DeliveryAddress): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(
      DRAFT_KEY,
      JSON.stringify({
        customerName: addr.customerName.trim(),
        phone: addr.phone.trim(),
        addressLine1: addr.addressLine1.trim(),
        city: addr.city.trim(),
        postalCode: addr.postalCode.trim(),
      }),
    );
  } catch {
    /* quota */
  }
}

/** Error message if invalid; `null` when OK to checkout. */
export function validateDeliveryForCheckout(addr: DeliveryAddress): string | null {
  const name = addr.customerName.trim();
  if (name.length < 2) return "Enter your full name.";

  const mobile = normalizeIndianMobile(addr.phone);
  if (!/^[6-9]\d{9}$/.test(mobile)) {
    return "Enter a valid 10-digit Indian mobile number.";
  }

  const line1 = addr.addressLine1.trim();
  if (line1.length < 5) return "Enter a complete street / building address.";

  const city = addr.city.trim();
  if (city.length < 2) return "Enter city or district.";

  const pin = stripDigits(addr.postalCode);
  if (!/^\d{6}$/.test(pin)) return "PIN code must be 6 digits.";

  return null;
}
