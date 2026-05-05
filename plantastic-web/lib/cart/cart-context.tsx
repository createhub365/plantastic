"use client";

import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

export type CartLine = {
  productId: string;
  productTitle: string;
  lineId: string;
  kitLabel: string;
  priceInr: number;
  qty: number;
};

type CartState = {
  lines: CartLine[];
  itemCount: number;
  subtotalInr: number;
  add: (input: Omit<CartLine, "qty"> & { qty?: number }) => void;
  /** Replaces the whole cart with this line, then navigate to `/cart` from the caller (express checkout). */
  buyNow: (input: Omit<CartLine, "qty"> & { qty?: number }) => void;
  setQty: (productId: string, lineId: string, qty: number) => void;
  remove: (productId: string, lineId: string) => void;
  clear: () => void;
};

const CartContext = createContext<CartState | null>(null);

const STORAGE_KEY = "plantastic.web.cart.v1";

function readStored(): CartLine[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((row) => {
        if (!row || typeof row !== "object") return null;
        const r = row as Record<string, unknown>;
        const productId = `${r.productId ?? ""}`;
        const lineId = `${r.lineId ?? ""}`;
        if (!productId || !lineId) return null;
        const qty = Number(r.qty ?? 1) || 1;
        return {
          productId,
          productTitle: `${r.productTitle ?? ""}`,
          lineId,
          kitLabel: `${r.kitLabel ?? "Kit"}`,
          priceInr: Number(r.priceInr ?? 0) || 0,
          qty: Math.max(1, Math.floor(qty)),
        } satisfies CartLine;
      })
      .filter((x): x is CartLine => x != null);
  } catch {
    return [];
  }
}

function totals(lines: CartLine[]) {
  const itemCount = lines.reduce((a, l) => a + l.qty, 0);
  const subtotalInr = lines.reduce((a, l) => a + l.qty * l.priceInr, 0);
  return { itemCount, subtotalInr };
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [lines, setLines] = useState<CartLine[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setLines(readStored());
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(lines));
    } catch {
      /* ignore quota */
    }
  }, [lines, hydrated]);

  const add = useCallback((input: Omit<CartLine, "qty"> & { qty?: number }) => {
    const qty = Math.max(1, Math.floor(input.qty ?? 1));
    setLines((prev) => {
      const idx = prev.findIndex(
        (l) => l.productId === input.productId && l.lineId === input.lineId,
      );
      if (idx < 0) {
        return [
          ...prev,
          {
            productId: input.productId,
            productTitle: input.productTitle,
            lineId: input.lineId,
            kitLabel: input.kitLabel,
            priceInr: input.priceInr,
            qty,
          },
        ];
      }
      const copy = [...prev];
      const cur = copy[idx];
      copy[idx] = { ...cur, qty: cur.qty + qty };
      return copy;
    });
  }, []);

  const buyNow = useCallback(
    (input: Omit<CartLine, "qty"> & { qty?: number }) => {
      const qty = Math.max(1, Math.floor(input.qty ?? 1));
      setLines([
        {
          productId: input.productId,
          productTitle: input.productTitle,
          lineId: input.lineId,
          kitLabel: input.kitLabel,
          priceInr: input.priceInr,
          qty,
        },
      ]);
    },
    [],
  );

  const setQty = useCallback((productId: string, lineId: string, qty: number) => {
    const q = Math.max(0, Math.floor(qty));
    setLines((prev) => {
      if (q === 0) {
        return prev.filter(
          (l) => !(l.productId === productId && l.lineId === lineId),
        );
      }
      return prev.map((l) =>
        l.productId === productId && l.lineId === lineId ? { ...l, qty: q } : l,
      );
    });
  }, []);

  const remove = useCallback((productId: string, lineId: string) => {
    setLines((prev) =>
      prev.filter((l) => !(l.productId === productId && l.lineId === lineId)),
    );
  }, []);

  const clear = useCallback(() => setLines([]), []);

  const value = useMemo<CartState>(() => {
    const t = totals(lines);
    return {
      lines,
      itemCount: t.itemCount,
      subtotalInr: t.subtotalInr,
      add,
      buyNow,
      setQty,
      remove,
      clear,
    };
  }, [lines, add, buyNow, setQty, remove, clear]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartState {
  const ctx = useContext(CartContext);
  if (!ctx) {
    throw new Error("useCart must be used within CartProvider");
  }
  return ctx;
}
