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
      className="flex min-h-full flex-col md:flex-row"
      style={{
        backgroundColor: colors.pageGradientTop,
        color: colors.textPrimary,
      }}
    >
      <aside
        className="flex w-full shrink-0 flex-col border-b px-3 py-3 md:w-64 md:border-b-0 md:border-r md:py-4"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <div
          className="mb-2 hidden px-2 text-xs font-semibold uppercase tracking-wide md:block"
          style={{ color: colors.textSecondary }}
        >
          Plantastic admin
        </div>
        <p
          className="mb-3 hidden px-2 text-[11px] leading-snug md:mb-4 md:block"
          style={{ color: colors.textSecondary }}
        >
          Catalogue & fulfilment
        </p>
        <nav className="flex flex-none flex-row gap-1 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] md:flex-1 md:flex-col md:gap-0.5 md:overflow-visible md:pb-0 [&::-webkit-scrollbar]:hidden">
          {nav.map(({ href, label, icon }) => (
            <Link
              key={href}
              href={href}
              className="flex shrink-0 touch-manipulation items-center gap-2 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors hover:opacity-80 md:px-2 md:py-2"
              style={{ color: colors.textPrimary }}
            >
              <PhosphorIcon icon={icon} size="sm" />
              {label}
            </Link>
          ))}
          <Link
            href="/"
            className="mt-0 flex shrink-0 touch-manipulation items-center gap-2 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors hover:opacity-90 md:mt-4 md:px-2 md:py-2"
            style={{ color: colors.primary }}
          >
            <PhosphorIcon icon={Storefront} size="sm" color={colors.primary} />
            View shop
          </Link>
        </nav>
        <div
          className="mt-3 space-y-2 border-t pt-3 md:mt-auto"
          style={{ borderColor: colors.border }}
        >
          {userEmail ? (
            <>
              <p
                className="truncate px-2 text-[10px] leading-tight md:hidden"
                style={{ color: colors.textSecondary }}
              >
                {userEmail}
              </p>
              <p
                className="hidden truncate px-2 text-xs md:block"
                style={{ color: colors.textSecondary }}
              >
                {userEmail}
              </p>
            </>
          ) : null}
          <form action={signOutAdmin}>
            <button
              type="submit"
              className="flex w-full touch-manipulation items-center gap-2 rounded-lg px-3 py-2.5 text-left text-sm transition-colors hover:opacity-80 md:px-2 md:py-2"
              style={{ color: colors.textPrimary }}
            >
              <PhosphorIcon icon={SignOut} size="sm" />
              Sign out
            </button>
          </form>
        </div>
      </aside>
      <div className="min-w-0 flex-1 overflow-x-hidden p-3 pb-[max(1rem,env(safe-area-inset-bottom))] sm:p-4 md:p-6">
        {children}
      </div>
    </div>
  );
}
