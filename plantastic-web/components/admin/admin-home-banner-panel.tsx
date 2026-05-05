"use client";

import { useRouter } from "next/navigation";
import { startTransition, useEffect, useState } from "react";
import {
  adminResetHomeBannerGradient,
  adminSaveHomeBannerJson,
} from "@/lib/admin/catalog-actions";
import { homeBannerFallback } from "@/lib/catalog/home-banner";
import type { HomeBannerSlide, ShopHomeBanner } from "@/lib/catalog/types";
import { colors } from "@/lib/theme/colors";

export function AdminHomeBannerPanel({ initial }: { initial: ShopHomeBanner }) {
  const router = useRouter();
  const [title, setTitle] = useState(initial.titleOverlay);
  const [slides, setSlides] = useState<HomeBannerSlide[]>(() => {
    const from = initial.slides.filter((s) => s.url.trim());
    if (from.length > 0) return from.map((s) => ({ ...s }));
    const u = initial.mediaUrl?.trim();
    if (u && initial.mediaKind !== "gradient") {
      return [
        {
          kind: initial.mediaKind === "video" ? "video" : "image",
          url: u,
          caption: initial.titleOverlay,
        },
      ];
    }
    return [{ kind: "image" as const, url: "", caption: "" }];
  });
  const [interval, setInterval] = useState(initial.carouselIntervalMs);
  const [h, setH] = useState(initial.bannerHeightPx);
  const [minH, setMinH] = useState(initial.bannerMinHeightPx);
  const [maxH, setMaxH] = useState(initial.bannerMaxHeightPx);
  const [glassBlur, setGlassBlur] = useState(initial.glassBlur);
  const [glassSigma, setGlassSigma] = useState(initial.glassSigma);
  const [glassFill, setGlassFill] = useState(initial.glassFillAlpha);
  const [glassBorder, setGlassBorder] = useState(initial.glassBorderAlpha);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    setTitle(initial.titleOverlay);
    setInterval(initial.carouselIntervalMs);
    setH(initial.bannerHeightPx);
    setMinH(initial.bannerMinHeightPx);
    setMaxH(initial.bannerMaxHeightPx);
    setGlassBlur(initial.glassBlur);
    setGlassSigma(initial.glassSigma);
    setGlassFill(initial.glassFillAlpha);
    setGlassBorder(initial.glassBorderAlpha);
    const from = initial.slides.filter((s) => s.url.trim());
    if (from.length > 0) {
      setSlides(from.map((s) => ({ ...s })));
    } else {
      const u = initial.mediaUrl?.trim();
      if (u && initial.mediaKind !== "gradient") {
        setSlides([
          {
            kind: initial.mediaKind === "video" ? "video" : "image",
            url: u,
            caption: initial.titleOverlay,
          },
        ]);
      } else {
        setSlides([{ kind: "image", url: "", caption: "" }]);
      }
    }
  }, [initial]);

  const addSlide = () => {
    setSlides((s) => [...s, { kind: "image", url: "", caption: "" }]);
  };

  const updateSlide = (i: number, patch: Partial<HomeBannerSlide>) => {
    setSlides((rows) => rows.map((row, j) => (j === i ? { ...row, ...patch } : row)));
  };

  const removeSlide = (i: number) => {
    setSlides((rows) => rows.filter((_, j) => j !== i));
  };

  const save = () => {
    setMsg(null);
    const cfg: ShopHomeBanner = {
      ...homeBannerFallback(),
      ...initial,
      mediaKind: "gradient",
      mediaUrl: null,
      titleOverlay: title.trim() || homeBannerFallback().titleOverlay,
      slides,
      carouselIntervalMs: interval,
      bannerHeightPx: h,
      bannerMinHeightPx: minH,
      bannerMaxHeightPx: maxH,
      glassBlur,
      glassSigma,
      glassFillAlpha: glassFill,
      glassBorderAlpha: glassBorder,
    };
    setBusy(true);
    startTransition(() => {
      void adminSaveHomeBannerJson(JSON.stringify(cfg)).then((r) => {
        setBusy(false);
        if (r.error) setMsg(r.error);
        else {
          setMsg("Saved.");
          router.refresh();
        }
      });
    });
  };

  const useGradientOnly = () => {
    setMsg(null);
    setBusy(true);
    startTransition(() => {
      void adminResetHomeBannerGradient(title).then((r) => {
        setBusy(false);
        if (r.error) setMsg(r.error);
        else {
          router.refresh();
        }
      });
    });
  };

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <p className="text-sm" style={{ color: colors.textSecondary }}>
        Hero carousel URLs (no file upload yet — paste Supabase/CDN URLs). Matches Flutter saving{" "}
        <code className="text-xs">slides</code> + sizing + glass flags.
      </p>
      {msg ? (
        <p className={`text-sm ${msg.startsWith("Saved") ? "" : "text-red-600"}`}>{msg}</p>
      ) : null}

      <label className="block text-sm font-medium">
        Default title / caption fallback
        <input
          className="mt-1 w-full rounded-lg border px-3 py-2"
          style={{ borderColor: colors.border }}
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
      </label>

      <div className="grid gap-3 sm:grid-cols-2">
        <label className="text-sm">
          Carousel interval (ms)
          <input
            type="number"
            className="mt-1 w-full rounded border px-2 py-1.5"
            style={{ borderColor: colors.border }}
            value={interval}
            onChange={(e) => setInterval(Number(e.target.value) || 5000)}
          />
        </label>
        <label className="text-sm">
          Banner height (px)
          <input
            type="number"
            className="mt-1 w-full rounded border px-2 py-1.5"
            style={{ borderColor: colors.border }}
            value={h}
            onChange={(e) => setH(Number(e.target.value) || 160)}
          />
        </label>
        <label className="text-sm">
          Min height
          <input
            type="number"
            className="mt-1 w-full rounded border px-2 py-1.5"
            style={{ borderColor: colors.border }}
            value={minH}
            onChange={(e) => setMinH(Number(e.target.value) || 120)}
          />
        </label>
        <label className="text-sm">
          Max height
          <input
            type="number"
            className="mt-1 w-full rounded border px-2 py-1.5"
            style={{ borderColor: colors.border }}
            value={maxH}
            onChange={(e) => setMaxH(Number(e.target.value) || 280)}
          />
        </label>
      </div>

      <fieldset className="space-y-2 rounded-xl border p-3 text-sm" style={{ borderColor: colors.border }}>
        <legend className="font-semibold">Glass (stored for parity)</legend>
        <label className="flex items-center gap-2">
          <input type="checkbox" checked={glassBlur} onChange={(e) => setGlassBlur(e.target.checked)} />
          Blur
        </label>
        <label>
          Sigma
          <input
            type="number"
            className="mt-1 w-full rounded border px-2 py-1"
            style={{ borderColor: colors.border }}
            value={glassSigma}
            onChange={(e) => setGlassSigma(Number(e.target.value) || 0)}
          />
        </label>
        <label>
          Fill α
          <input
            type="number"
            step="0.01"
            className="mt-1 w-full rounded border px-2 py-1"
            style={{ borderColor: colors.border }}
            value={glassFill}
            onChange={(e) => setGlassFill(Number(e.target.value) || 0)}
          />
        </label>
        <label>
          Border α
          <input
            type="number"
            step="0.01"
            className="mt-1 w-full rounded border px-2 py-1"
            style={{ borderColor: colors.border }}
            value={glassBorder}
            onChange={(e) => setGlassBorder(Number(e.target.value) || 0)}
          />
        </label>
      </fieldset>

      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-extrabold uppercase" style={{ color: colors.primary }}>
            Slides
          </h2>
          <button
            type="button"
            onClick={addSlide}
            className="rounded border px-3 py-1 text-xs font-semibold"
            style={{ borderColor: colors.border }}
          >
            + Slide
          </button>
        </div>
        {slides.map((s, i) => (
          <div
            key={i}
            className="space-y-2 rounded-xl border p-3"
            style={{ borderColor: colors.border }}
          >
            <div className="flex justify-between">
              <span className="text-xs font-semibold">Slide {i + 1}</span>
              {slides.length > 1 ? (
                <button type="button" className="text-xs text-red-700" onClick={() => removeSlide(i)}>
                  Remove
                </button>
              ) : null}
            </div>
            <label className="block text-xs">
              Kind
              <select
                className="mt-1 w-full rounded border px-2 py-1"
                style={{ borderColor: colors.border }}
                value={s.kind}
                onChange={(e) =>
                  updateSlide(i, {
                    kind: e.target.value === "video" ? "video" : "image",
                  })
                }
              >
                <option value="image">image</option>
                <option value="video">video</option>
              </select>
            </label>
            <label className="block text-xs">
              URL
              <input
                className="mt-1 w-full rounded border px-2 py-1 font-mono text-[11px]"
                style={{ borderColor: colors.border }}
                value={s.url}
                onChange={(e) => updateSlide(i, { url: e.target.value })}
              />
            </label>
            <label className="block text-xs">
              Caption
              <input
                className="mt-1 w-full rounded border px-2 py-1 text-xs"
                style={{ borderColor: colors.border }}
                value={s.caption}
                onChange={(e) => updateSlide(i, { caption: e.target.value })}
              />
            </label>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap gap-3">
        <button
          type="button"
          disabled={busy}
          onClick={save}
          className="rounded-lg px-5 py-2 text-sm font-semibold text-white disabled:opacity-50"
          style={{ backgroundColor: colors.primary }}
        >
          {busy ? "Saving…" : "Save banner"}
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={useGradientOnly}
          className="rounded-lg border px-5 py-2 text-sm disabled:opacity-50"
          style={{ borderColor: colors.border }}
        >
          Gradient only
        </button>
      </div>
    </div>
  );
}
