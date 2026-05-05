/**
 * Plantastic logo mark — used in header; keep in sync with `public/favicon.svg`.
 */

export function BrandMark({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 64 64"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <rect width="64" height="64" rx="16" fill="#2E7D32" />
      {/* Stem */}
      <path
        d="M32 50V30"
        stroke="#E8F5E9"
        strokeWidth="3.2"
        strokeLinecap="round"
      />
      {/* Left leaf */}
      <path
        d="M32 32C24 24 14 22 14 14c0-6 6-9 12-6 6 3 7 12 6 18z"
        fill="#A5D6A7"
      />
      {/* Right leaf */}
      <path
        d="M32 32C40 24 50 22 50 14c0-6-6-9-12-6-6 3-7 12-6 18z"
        fill="#C8E6C9"
      />
      {/* Top sprout */}
      <circle cx="32" cy="28" r="4" fill="#E8F5E9" />
    </svg>
  );
}
