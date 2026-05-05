import type { Metadata, Viewport } from "next";
import { Poppins } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers";
import { SiteHeader } from "@/components/site-header";
import { colors } from "@/lib/theme/colors";

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-poppins",
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Plantastic",
    template: "%s · Plantastic",
  },
  description: "Plants, seeds, and starter kits for home gardeners.",
  icons: {
    icon: "/favicon.svg",
  },
};

/** Mobile: correct scaling, notched phones, Safari dynamic toolbar (`svh` on main below). */
export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${poppins.variable} h-full`}>
      <body
        className="min-h-full font-sans antialiased"
        style={{
          backgroundColor: colors.background,
          color: colors.textPrimary,
          fontFamily: "var(--font-poppins), system-ui, sans-serif",
        }}
      >
        <Providers>
          <SiteHeader />
          <main className="min-h-[calc(100svh-env(safe-area-inset-top)-3.5rem-max(12px,env(safe-area-inset-bottom)))] pb-[max(12px,env(safe-area-inset-bottom))] sm:min-h-[calc(100svh-env(safe-area-inset-top)-3.75rem-max(12px,env(safe-area-inset-bottom)))]">
            {children}
          </main>
        </Providers>
      </body>
    </html>
  );
}
