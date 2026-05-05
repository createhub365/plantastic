import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Order placed",
  description: "Your Plantastic order confirmation.",
};

export default function CheckoutSuccessLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
