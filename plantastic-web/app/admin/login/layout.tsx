import { colors } from "@/lib/theme/colors";

export default function AdminLoginLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div
      className="flex min-h-[calc(100vh-56px)] flex-col items-center justify-center px-4 py-10 sm:min-h-[calc(100vh-60px)]"
      style={{
        backgroundColor: colors.pageGradientTop,
        color: colors.textPrimary,
      }}
    >
      {children}
    </div>
  );
}
