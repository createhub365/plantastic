"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  startTransition,
  useCallback,
  useMemo,
  useState,
} from "react";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import {
  adminSaveProductJson,
  type AdminSaveProductPayload,
} from "@/lib/admin/catalog-actions";
import { CATEGORY_FLOWER_SEED, CATEGORY_PLANT_SEED } from "@/lib/catalog/constants";
import type { ProductKitLine, ShopProduct } from "@/lib/catalog/types";
import { colors } from "@/lib/theme/colors";

function kitRowKey(k: ProductKitLine, i: number) {
  return k.lineId || `idx-${i}`;
}

export function AdminProductEditor({
  initial,
  highlightCatalog,
}: {
  initial: ShopProduct;
  highlightCatalog: HighlightTag[];
}) {
  const router = useRouter();
  const [product, setProduct] = useState<ShopProduct>(initial);
  const [galleryText, setGalleryText] = useState(
    initial.galleryUrls.join("\n"),
  );
  const [metaJson, setMetaJson] = useState(
    JSON.stringify(
      (initial.gallerySlideMeta ?? []).map((m) => ({
        flowerName: m.flowerName,
        snippet: m.snippet ?? "",
      })),
      null,
      2,
    ),
  );
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const sortedHighlights = useMemo(
    () => [...highlightCatalog].sort((a, b) => a.sortOrder - b.sortOrder),
    [highlightCatalog],
  );

  const toggleHighlight = useCallback((id: string) => {
    setProduct((p) => {
      const has = p.highlightTagIds.includes(id);
      return {
        ...p,
        highlightTagIds: has
          ? p.highlightTagIds.filter((x) => x !== id)
          : [...p.highlightTagIds, id],
      };
    });
  }, []);

  const updateKit = useCallback(
    (i: number, patch: Partial<ProductKitLine>) => {
      setProduct((p) => {
        const kits = [...p.kits];
        const cur = kits[i];
        if (!cur) return p;
        kits[i] = { ...cur, ...patch };
        return { ...p, kits };
      });
    },
    [],
  );

  const addKit = useCallback(() => {
    const id = `k_${crypto.randomUUID()}`;
    setProduct((p) => ({
      ...p,
      kits: [
        ...p.kits,
        {
          lineId: id,
          label: "New kit",
          catalogIds: [],
          priceInr: 599,
          presetId: null,
          snapshotLines: [],
          imageUrls: [],
        },
      ],
    }));
  }, []);

  const removeKit = useCallback((i: number) => {
    setProduct((p) => {
      if (p.kits.length <= 1) return p;
      return { ...p, kits: p.kits.filter((_, j) => j !== i) };
    });
  }, []);

  const save = () => {
    setMessage(null);
    const galleryUrls = galleryText
      .split("\n")
      .map((s) => s.trim())
      .filter(Boolean);

    let gallerySlideMeta: AdminSaveProductPayload["gallerySlideMeta"] = [];
    const trimmed = metaJson.trim();
    if (trimmed.length > 0) {
      try {
        const parsed = JSON.parse(trimmed) as unknown;
        if (!Array.isArray(parsed)) {
          setMessage("Gallery meta must be a JSON array.");
          return;
        }
        gallerySlideMeta = parsed.map((e) => {
          if (!e || typeof e !== "object") return { flowerName: "" };
          const o = e as Record<string, unknown>;
          const flowerName = `${o.flowerName ?? o.flower_name ?? ""}`.trim();
          const snippet = `${o.snippet ?? ""}`.trim();
          return {
            flowerName,
            ...(snippet ? { snippet } : {}),
          };
        });
      } catch {
        setMessage("Gallery meta JSON is invalid.");
        return;
      }
    }

    const payload: AdminSaveProductPayload = {
      id: product.id.trim() || undefined,
      title: product.title,
      subtitle: product.subtitle,
      category: product.category,
      galleryUrls,
      coverImageUrl: product.coverImageUrl,
      gallerySlideMeta,
      kits: product.kits,
      highlightTagIds: product.highlightTagIds,
      inStock: product.inStock,
      visibleInShop: product.visibleInShop,
    };

    setBusy(true);
    startTransition(() => {
      void adminSaveProductJson(JSON.stringify(payload)).then((r) => {
        setBusy(false);
        if (r.error) {
          setMessage(r.error);
          return;
        }
        const newId = r.id?.trim();
        if (newId && !product.id) {
          router.replace(`/admin/products/${newId}/edit`);
        }
        router.refresh();
        setMessage("Saved.");
      });
    });
  };

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Link
          href="/admin/products"
          className="text-sm font-medium underline"
          style={{ color: colors.primary }}
        >
          ← All products
        </Link>
        <button
          type="button"
          disabled={busy}
          onClick={save}
          className="rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          style={{ backgroundColor: colors.primary }}
        >
          {busy ? "Saving…" : "Save product"}
        </button>
      </div>

      {message ? (
        <p
          className={`text-sm ${message === "Saved." ? "" : "text-red-600"}`}
          role="status"
        >
          {message}
        </p>
      ) : null}

      <div
        className="space-y-4 rounded-xl border p-4"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <h2
          className="text-sm font-extrabold uppercase tracking-wide"
          style={{ color: colors.primary }}
        >
          Basics
        </h2>
        <label className="block text-sm">
          <span className="font-medium">Title</span>
          <input
            className="mt-1 w-full rounded-lg border px-3 py-2"
            style={{ borderColor: colors.border }}
            value={product.title}
            onChange={(e) =>
              setProduct((p) => ({ ...p, title: e.target.value }))
            }
          />
        </label>
        <label className="block text-sm">
          <span className="font-medium">Subtitle</span>
          <input
            className="mt-1 w-full rounded-lg border px-3 py-2"
            style={{ borderColor: colors.border }}
            value={product.subtitle}
            onChange={(e) =>
              setProduct((p) => ({ ...p, subtitle: e.target.value }))
            }
          />
        </label>
        <label className="block text-sm">
          <span className="font-medium">Category</span>
          <select
            className="mt-1 w-full rounded-lg border px-3 py-2"
            style={{ borderColor: colors.border }}
            value={product.category}
            onChange={(e) =>
              setProduct((p) => ({ ...p, category: e.target.value }))
            }
          >
            <option value={CATEGORY_FLOWER_SEED}>{CATEGORY_FLOWER_SEED}</option>
            <option value={CATEGORY_PLANT_SEED}>{CATEGORY_PLANT_SEED}</option>
          </select>
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={product.inStock}
            onChange={(e) =>
              setProduct((p) => ({ ...p, inStock: e.target.checked }))
            }
          />
          In stock
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={product.visibleInShop}
            onChange={(e) =>
              setProduct((p) => ({ ...p, visibleInShop: e.target.checked }))
            }
          />
          Visible in shop
        </label>
      </div>

      <div
        className="space-y-4 rounded-xl border p-4"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <h2
          className="text-sm font-extrabold uppercase tracking-wide"
          style={{ color: colors.primary }}
        >
          Media
        </h2>
        <label className="block text-sm">
          <span className="font-medium">Cover image URL</span>
          <input
            className="mt-1 w-full rounded-lg border px-3 py-2 font-mono text-xs"
            style={{ borderColor: colors.border }}
            value={product.coverImageUrl}
            onChange={(e) =>
              setProduct((p) => ({ ...p, coverImageUrl: e.target.value }))
            }
          />
        </label>
        <label className="block text-sm">
          <span className="font-medium">Gallery URLs (one per line)</span>
          <textarea
            className="mt-1 min-h-[100px] w-full rounded-lg border px-3 py-2 font-mono text-xs"
            style={{ borderColor: colors.border }}
            value={galleryText}
            onChange={(e) => setGalleryText(e.target.value)}
          />
        </label>
        <label className="block text-sm">
          <span className="font-medium">Gallery slide meta (JSON array)</span>
          <textarea
            className="mt-1 min-h-[120px] w-full rounded-lg border px-3 py-2 font-mono text-xs"
            style={{ borderColor: colors.border }}
            value={metaJson}
            onChange={(e) => setMetaJson(e.target.value)}
            placeholder={`[\n  { "flowerName": "Rose", "snippet": "..." }\n]`}
          />
        </label>
      </div>

      <div
        className="space-y-4 rounded-xl border p-4"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2
            className="text-sm font-extrabold uppercase tracking-wide"
            style={{ color: colors.primary }}
          >
            Kits
          </h2>
          <button
            type="button"
            onClick={addKit}
            className="rounded-lg border px-3 py-1.5 text-xs font-semibold"
            style={{ borderColor: colors.border }}
          >
            + Add kit
          </button>
        </div>
        {product.kits.map((kit, i) => (
          <div
            key={kitRowKey(kit, i)}
            className="space-y-2 rounded-lg border p-3"
            style={{ borderColor: colors.border }}
          >
            <div className="flex justify-between gap-2">
              <span className="text-xs font-mono text-neutral-500">
                {kit.lineId}
              </span>
              {product.kits.length > 1 ? (
                <button
                  type="button"
                  className="text-xs text-red-600"
                  onClick={() => removeKit(i)}
                >
                  Remove
                </button>
              ) : null}
            </div>
            <label className="block text-xs">
              Label
              <input
                className="mt-0.5 w-full rounded border px-2 py-1.5"
                style={{ borderColor: colors.border }}
                value={kit.label}
                onChange={(e) => updateKit(i, { label: e.target.value })}
              />
            </label>
            <label className="block text-xs">
              Price (INR)
              <input
                type="number"
                className="mt-0.5 w-full rounded border px-2 py-1.5"
                style={{ borderColor: colors.border }}
                value={kit.priceInr}
                onChange={(e) =>
                  updateKit(i, {
                    priceInr: Number.parseInt(e.target.value, 10) || 0,
                  })
                }
              />
            </label>
            <label className="block text-xs">
              Catalog IDs (comma-separated UUIDs)
              <input
                className="mt-0.5 w-full rounded border px-2 py-1.5 font-mono"
                style={{ borderColor: colors.border }}
                value={kit.catalogIds.join(", ")}
                onChange={(e) =>
                  updateKit(i, {
                    catalogIds: e.target.value
                      .split(",")
                      .map((s) => s.trim())
                      .filter(Boolean),
                  })
                }
              />
            </label>
            <label className="block text-xs">
              Snapshot lines (when no catalog IDs; one per line)
              <textarea
                className="mt-0.5 min-h-[60px] w-full rounded border px-2 py-1.5 text-xs"
                style={{ borderColor: colors.border }}
                value={kit.snapshotLines.join("\n")}
                onChange={(e) =>
                  updateKit(i, {
                    snapshotLines: e.target.value
                      .split("\n")
                      .map((s) => s.trim())
                      .filter(Boolean),
                  })
                }
              />
            </label>
            <label className="block text-xs">
              Preset ID (optional)
              <input
                className="mt-0.5 w-full rounded border px-2 py-1.5 font-mono"
                style={{ borderColor: colors.border }}
                value={kit.presetId ?? ""}
                onChange={(e) =>
                  updateKit(i, {
                    presetId: e.target.value.trim() || null,
                  })
                }
              />
            </label>
            <label className="block text-xs">
              Kit image URLs (one per line; optional)
              <textarea
                className="mt-0.5 min-h-[50px] w-full rounded border px-2 py-1.5 font-mono text-[11px]"
                style={{ borderColor: colors.border }}
                value={kit.imageUrls.join("\n")}
                onChange={(e) =>
                  updateKit(i, {
                    imageUrls: e.target.value
                      .split("\n")
                      .map((s) => s.trim())
                      .filter(Boolean),
                  })
                }
              />
            </label>
          </div>
        ))}
      </div>

      <div
        className="space-y-3 rounded-xl border p-4"
        style={{ borderColor: colors.border, backgroundColor: colors.card }}
      >
        <h2
          className="text-sm font-extrabold uppercase tracking-wide"
          style={{ color: colors.primary }}
        >
          Highlights
        </h2>
        <div className="flex flex-col gap-2">
          {sortedHighlights.map((h) => (
            <label key={h.id} className="flex items-start gap-2 text-sm">
              <input
                type="checkbox"
                checked={product.highlightTagIds.includes(h.id)}
                onChange={() => toggleHighlight(h.id)}
              />
              <span>
                <span className="font-semibold">{h.title}</span>
                {h.label ? (
                  <span className="text-neutral-500"> — {h.label}</span>
                ) : null}
              </span>
            </label>
          ))}
        </div>
      </div>
    </div>
  );
}
