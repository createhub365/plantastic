"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import { PhosphorIcon } from "@/components/phosphor-icon";
import { House } from "@phosphor-icons/react/dist/csr/House";
import { Panorama } from "@phosphor-icons/react/dist/csr/Panorama";
import { ListChecks } from "@phosphor-icons/react/dist/csr/ListChecks";
import { Package } from "@phosphor-icons/react/dist/csr/Package";
import { ShoppingCart } from "@phosphor-icons/react/dist/csr/ShoppingCart";
import { SignOut } from "@phosphor-icons/react/dist/csr/SignOut";
import { Star } from "@phosphor-icons/react/dist/csr/Star";
import { Stack } from "@phosphor-icons/react/dist/csr/Stack";
import { Storefront } from "@phosphor-icons/react/dist/csr/Storefront";
import { signOutAdmin } from "@/lib/admin/actions";
import { colors } from "@/lib/theme/colors";

const nav = [
  { href: "/admin", label: "Dashboard", icon: House },
  { href: "/admin/products", label: "Products", icon: Package },
  { href: "/admin/orders", label: "Orders", icon: ShoppingCart },
  { href: "/admin/kit-items", label: "Kit items", icon: ListChecks },
  { href: "/admin/kit-presets", label: "Kit presets", icon: Stack },
  { href: "/admin/highlights", label: "Highlights", icon: Star },
  { href: "/admin/home-banner", label: "Home banner", icon: Panorama },
] as const;

export function AdminShell({
  userEmail,
  children,
}: {
  userEmail: string;
  children: ReactNode;
}) {
  return (
    <div
      className="flex min-h-full"
      style={{
        backgroundColor: colors.pageGradientTop,
        color: colors.textPrimary,
      }}
    >
      <aside
        className="flex w-56 shrink-0 flex-col border-r px-3 py-4 sm:w-64"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <div
          className="mb-2 px-2 text-xs font-semibold uppercase tracking-wide"
          style={{ color: colors.textSecondary }}
        >
          Plantastic admin
        </div>
        <p className="mb-4 px-2 text-[11px] leading-snug" style={{ color: colors.textSecondary }}>
          Catalogue & fulfilment
        </p>
        <nav className="flex flex-1 flex-col gap-0.5 text-sm font-medium">
          {nav.map(({ href, label, icon }) => (
            <Link
              key={href}
              href={href}
              className="flex items-center gap-2 rounded-lg px-2 py-2 transition-colors hover:opacity-80"
              style={{ color: colors.textPrimary }}
            >
              <PhosphorIcon icon={icon} size="sm" />
              {label}
            </Link>
          ))}
          <Link
            href="/"
            className="mt-4 flex items-center gap-2 rounded-lg px-2 py-2 transition-colors hover:opacity-90"
            style={{ color: colors.primary }}
          >
            <PhosphorIcon icon={Storefront} size="sm" color={colors.primary} />
            View shop
          </Link>
        </nav>
        <div className="mt-auto space-y-2 border-t pt-3" style={{ borderColor: colors.border }}>
          {userEmail ? (
            <p className="truncate px-2 text-xs" style={{ color: colors.textSecondary }}>
              {userEmail}
            </p>
          ) : null}
          <form action={signOutAdmin}>
            <button
              type="submit"
              className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-sm transition-colors hover:opacity-80"
              style={{ color: colors.textPrimary }}
            >
              <PhosphorIcon icon={SignOut} size="sm" />
              Sign out
            </button>
          </form>
        </div>
      </aside>
      <div className="min-w-0 flex-1 overflow-x-hidden p-4 sm:p-6">{children}</div>
    </div>
  );
}
