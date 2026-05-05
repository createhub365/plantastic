import type { Metadata } from "next";
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
          <main className="min-h-[calc(100vh-56px)] sm:min-h-[calc(100vh-60px)]">
            {children}
          </main>
        </Providers>
      </body>
    </html>
  );
}
