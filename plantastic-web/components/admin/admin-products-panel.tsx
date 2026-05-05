"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  startTransition,
  useCallback,
  useMemo,
  useState,
} from "react";
import {
  adminDeleteProducts,
  adminSetProductStock,
  adminSetProductVisible,
} from "@/lib/admin/catalog-actions";
import { CATEGORY_FLOWER_SEED, CATEGORY_PLANT_SEED } from "@/lib/catalog/constants";
import type { ShopProduct } from "@/lib/catalog/types";
import { lowestKitPriceInr } from "@/lib/catalog/parse-product";
import { colors } from "@/lib/theme/colors";

type StockFilter = "any" | "in" | "out";

export function AdminProductsPanel({ products }: { products: ShopProduct[] }) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("");
  const [stockFilter, setStockFilter] = useState<StockFilter>("any");
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return products.filter((p) => {
      if (categoryFilter && p.category !== categoryFilter) return false;
      if (stockFilter === "in" && !p.inStock) return false;
      if (stockFilter === "out" && p.inStock) return false;
      if (!q) return true;
      return (
        p.title.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q)
      );
    });
  }, [products, query, categoryFilter, stockFilter]);

  const toggleAll = () => {
    const ids = new Set(filtered.map((p) => p.id));
    if ([...ids].every((id) => selected.has(id))) {
      setSelected(new Set());
    } else {
      setSelected(ids);
    }
  };

  const toggleOne = (id: string) => {
    setSelected((prev) => {
      const n = new Set(prev);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });
  };

  const refresh = () => router.refresh();

  const doBulkDelete = () => {
    if (selected.size === 0) return;
    if (
      !window.confirm(`Delete ${selected.size} product(s)? This cannot be undone.`)
    )
      return;
    startTransition(() => {
      void adminDeleteProducts([...selected]).then(() => {
        setSelected(new Set());
        refresh();
      });
    });
  };

  const setStock = useCallback(
    (id: string, v: boolean) => {
      startTransition(() => {
        void adminSetProductStock(id, v).then(refresh);
      });
    },
    [router],
  );

  const setVisible = useCallback(
    (id: string, v: boolean) => {
      startTransition(() => {
        void adminSetProductVisible(id, v).then(refresh);
      });
    },
    [router],
  );

  const allFilteredSelected =
    filtered.length > 0 && filtered.every((p) => selected.has(p.id));

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <Link
          href="/admin/products/new"
          className="rounded-lg px-4 py-2 text-sm font-semibold text-white"
          style={{ backgroundColor: colors.primary }}
        >
          + Add product
        </Link>
        <input
          type="search"
          placeholder="Search products…"
          className="min-w-[200px] flex-1 rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: colors.border }}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <select
          className="rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: colors.border }}
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
        >
          <option value="">All categories</option>
          <option value={CATEGORY_FLOWER_SEED}>{CATEGORY_FLOWER_SEED}</option>
          <option value={CATEGORY_PLANT_SEED}>{CATEGORY_PLANT_SEED}</option>
        </select>
        <select
          className="rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: colors.border }}
          value={stockFilter}
          onChange={(e) => setStockFilter(e.target.value as StockFilter)}
        >
          <option value="any">Any stock</option>
          <option value="in">In stock</option>
          <option value="out">Out of stock</option>
        </select>
      </div>

      <div className="text-xs" style={{ color: colors.textSecondary }}>
        {filtered.length} shown
      </div>

      {selected.size > 0 ? (
        <div
          className="flex flex-wrap items-center gap-3 rounded-xl border px-4 py-2"
          style={{ borderColor: colors.primary }}
        >
          <span className="text-sm font-semibold">{selected.size} selected</span>
          <button type="button" className="text-sm text-red-700" onClick={doBulkDelete}>
            Delete selected
          </button>
          <button
            type="button"
            className="text-sm"
            style={{ color: colors.textSecondary }}
            onClick={() => setSelected(new Set())}
          >
            Clear
          </button>
        </div>
      ) : null}

      <div
        className="overflow-x-auto rounded-xl border"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <table className="w-full min-w-[880px] text-left text-sm">
          <thead>
            <tr className="border-b" style={{ borderColor: colors.border }}>
              <th className="w-10 px-3 py-3">
                <input
                  type="checkbox"
                  aria-label="Select all visible"
                  checked={allFilteredSelected}
                  onChange={toggleAll}
                />
              </th>
              <th className="px-3 py-3 font-semibold">Product</th>
              <th className="px-3 py-3 font-semibold">Category</th>
              <th className="px-3 py-3 font-semibold">From ₹</th>
              <th className="px-3 py-3 font-semibold">Shop</th>
              <th className="px-3 py-3 font-semibold">Stock</th>
              <th className="px-3 py-3 font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-3 py-8 text-center text-neutral-500">
                  No products match filters.
                </td>
              </tr>
            ) : (
              filtered.map((p) => (
                <tr key={p.id} className="border-b last:border-0" style={{ borderColor: colors.border }}>
                  <td className="px-3 py-3">
                    <input
                      type="checkbox"
                      checked={selected.has(p.id)}
                      onChange={() => toggleOne(p.id)}
                    />
                  </td>
                  <td className="px-3 py-3 font-semibold">{p.title || "—"}</td>
                  <td className="px-3 py-3" style={{ color: colors.textSecondary }}>
                    {p.category || "—"}
                  </td>
                  <td className="px-3 py-3 tabular-nums">₹{lowestKitPriceInr(p)}</td>
                  <td className="px-3 py-3">
                    <button
                      type="button"
                      className="text-xs underline"
                      onClick={() => setVisible(p.id, !p.visibleInShop)}
                    >
                      {p.visibleInShop ? "Yes" : "Hidden"}
                    </button>
                  </td>
                  <td className="px-3 py-3">
                    <label className="flex cursor-pointer items-center gap-2 text-xs">
                      <input
                        type="checkbox"
                        checked={p.inStock}
                        onChange={(e) => setStock(p.id, e.target.checked)}
                      />
                      In stock
                    </label>
                  </td>
                  <td className="px-3 py-3">
                    <Link
                      href={`/admin/products/${p.id}/edit`}
                      className="font-semibold underline"
                      style={{ color: colors.primary }}
                    >
                      Edit
                    </Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
