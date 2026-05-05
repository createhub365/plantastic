"use client";

import { useRouter } from "next/navigation";
import { startTransition, useEffect, useMemo, useState } from "react";
import {
  adminCreateKitPreset,
  adminDeleteKitPreset,
  adminReorderKitPresets,
  adminUpdateKitPreset,
} from "@/lib/admin/catalog-actions";
import type { KitPreset } from "@/lib/catalog/kit-preset";
import { colors } from "@/lib/theme/colors";

export function AdminKitPresetsPanel({ initial }: { initial: KitPreset[] }) {
  const router = useRouter();
  const [items, setItems] = useState(initial);
  const [name, setName] = useState("");
  const [catalogCsv, setCatalogCsv] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => setItems(initial), [initial]);

  const ordered = useMemo(
    () => [...items].sort((a, b) => a.sortOrder - b.sortOrder),
    [items],
  );

  const persistOrder = (next: KitPreset[]) => {
    setBusy(true);
    startTransition(() => {
      void adminReorderKitPresets(next.map((p) => p.id)).then((r) => {
        setBusy(false);
        if (r.error) setErr(r.error);
        router.refresh();
      });
    });
  };

  const move = (i: number, dir: -1 | 1) => {
    const j = i + dir;
    if (j < 0 || j >= ordered.length) return;
    const next = [...ordered];
    [next[i], next[j]] = [next[j]!, next[i]!];
    setItems(next);
    persistOrder(next);
  };

  const add = () => {
    const n = name.trim();
    if (!n) return;
    const ids = catalogCsv
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    setBusy(true);
    startTransition(() => {
      void adminCreateKitPreset({ name: n, catalogIds: ids }).then((r) => {
        setBusy(false);
        setName("");
        setCatalogCsv("");
        if (r.error) setErr(r.error);
        router.refresh();
      });
    });
  };

  return (
    <div className="space-y-4">
      <p className="text-sm" style={{ color: colors.textSecondary }}>
        Named bundles of kit catalogue IDs (starter / deluxe presets). Same table as Flutter{" "}
        <code className="text-xs">kit_presets</code>.
      </p>
      {err ? <p className="text-sm text-red-600">{err}</p> : null}

      <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap">
        <input
          className="min-w-[160px] flex-1 rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: colors.border }}
          placeholder="Preset name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <input
          className="min-w-[220px] flex-[2] rounded-lg border px-3 py-2 font-mono text-xs"
          style={{ borderColor: colors.border }}
          placeholder="Catalog UUIDs, comma-separated"
          value={catalogCsv}
          onChange={(e) => setCatalogCsv(e.target.value)}
        />
        <button
          type="button"
          disabled={busy}
          onClick={add}
          className="rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          style={{ backgroundColor: colors.primary }}
        >
          Add preset
        </button>
      </div>

      <ul className="space-y-2">
        {ordered.map((p, i) => (
          <PresetRow
            key={p.id}
            preset={p}
            disabled={busy}
            onMoveUp={() => move(i, -1)}
            onMoveDown={() => move(i, 1)}
            onSaved={() => router.refresh()}
            onError={setErr}
          />
        ))}
      </ul>
    </div>
  );
}

function PresetRow({
  preset,
  disabled,
  onMoveUp,
  onMoveDown,
  onSaved,
  onError,
}: {
  preset: KitPreset;
  disabled: boolean;
  onMoveUp: () => void;
  onMoveDown: () => void;
  onSaved: () => void;
  onError: (s: string | null) => void;
}) {
  const [name, setName] = useState(preset.name);
  const [csv, setCsv] = useState(preset.catalogIds.join(", "));

  const save = () => {
    onError(null);
    startTransition(() => {
      void adminUpdateKitPreset({
        id: preset.id,
        name: name.trim(),
        catalogIds: csv
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
        sortOrder: preset.sortOrder,
      }).then((r) => {
        if (r.error) onError(r.error);
        onSaved();
      });
    });
  };

  const del = () => {
    if (!window.confirm("Delete this preset?")) return;
    onError(null);
    startTransition(() => {
      void adminDeleteKitPreset(preset.id).then((r) => {
        if (r.error) onError(r.error);
        onSaved();
      });
    });
  };

  return (
    <li
      className="space-y-2 rounded-xl border px-3 py-3"
      style={{ borderColor: colors.border, backgroundColor: colors.card }}
    >
      <div className="flex flex-wrap items-center gap-2">
        <div className="flex flex-col">
          <button type="button" className="text-xs" onClick={onMoveUp}>
            ↑
          </button>
          <button type="button" className="text-xs" onClick={onMoveDown}>
            ↓
          </button>
        </div>
        <input
          className="min-w-[120px] flex-1 rounded border px-2 py-1.5 text-sm font-semibold"
          style={{ borderColor: colors.border }}
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <span className="font-mono text-[10px] text-neutral-400">{preset.id.slice(0, 8)}…</span>
      </div>
      <textarea
        className="w-full rounded border px-2 py-1.5 font-mono text-xs"
        style={{ borderColor: colors.border }}
        rows={2}
        value={csv}
        onChange={(e) => setCsv(e.target.value)}
      />
      <div className="flex gap-2">
        <button
          type="button"
          disabled={disabled}
          className="rounded border px-3 py-1 text-xs"
          style={{ borderColor: colors.border }}
          onClick={save}
        >
          Save
        </button>
        <button type="button" className="text-xs text-red-700" onClick={del}>
          Delete
        </button>
      </div>
    </li>
  );
}
