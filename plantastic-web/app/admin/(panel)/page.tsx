import Link from "next/link";
import { colors } from "@/lib/theme/colors";

const links = [
  { href: "/admin/products", label: "Products" },
  { href: "/admin/orders", label: "Orders" },
  { href: "/admin/kit-items", label: "Kit items" },
  { href: "/admin/kit-presets", label: "Kit presets" },
  { href: "/admin/highlights", label: "Highlights" },
  { href: "/admin/home-banner", label: "Home banner" },
] as const;

export default function AdminDashboardPage() {
  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight">Dashboard</h1>
      <p className="mt-2 max-w-xl text-sm" style={{ color: colors.textSecondary }}>
        Same sections as the Flutter admin app — manage catalogue, presets, banner, orders, and
        fulfilment status.
      </p>
      <ul className="mt-8 flex flex-wrap gap-x-10 gap-y-3 text-sm font-semibold">
        {links.map((l) => (
          <li key={l.href}>
            <Link href={l.href} className="underline" style={{ color: colors.primary }}>
              {l.label} →
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
