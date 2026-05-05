"use client";

import { useRouter } from "next/navigation";
import {
  startTransition,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  adminCreateKitCatalogItem,
  adminDeleteKitCatalogItem,
  adminReorderKitCatalog,
  adminUpdateKitCatalogLabel,
} from "@/lib/admin/catalog-actions";
import type { KitCatalogItem } from "@/lib/catalog/kit-catalog";
import { colors } from "@/lib/theme/colors";

export function AdminKitCatalogPanel({ initial }: { initial: KitCatalogItem[] }) {
  const router = useRouter();
  const [items, setItems] = useState(initial);
  const [label, setLabel] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    setItems(initial);
  }, [initial]);

  const ordered = useMemo(
    () => [...items].sort((a, b) => a.sortOrder - b.sortOrder),
    [items],
  );

  const persistOrder = (next: KitCatalogItem[]) => {
    setBusy(true);
    setErr(null);
    startTransition(() => {
      void adminReorderKitCatalog(next.map((k) => k.id)).then((r) => {
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
    const t = label.trim();
    if (!t) return;
    setBusy(true);
    setErr(null);
    startTransition(() => {
      void adminCreateKitCatalogItem(t).then((r) => {
        setBusy(false);
        setLabel("");
        if (r.error) setErr(r.error);
        router.refresh();
      });
    });
  };

  const saveLabel = (id: string, lab: string) => {
    setBusy(true);
    startTransition(() => {
      void adminUpdateKitCatalogLabel(id, lab).then((r) => {
        setBusy(false);
        if (r.error) setErr(r.error);
        router.refresh();
      });
    });
  };

  const del = (id: string) => {
    if (!window.confirm("Remove this kit catalogue item?")) return;
    setBusy(true);
    startTransition(() => {
      void adminDeleteKitCatalogItem(id).then((r) => {
        setBusy(false);
        if (r.error) setErr(r.error);
        router.refresh();
      });
    });
  };

  return (
    <div className="space-y-4">
      <p className="text-sm" style={{ color: colors.textSecondary }}>
        Checklist labels for “What&apos;s inside”. Reorder like Flutter (sort_order).
      </p>

      {err ? <p className="text-sm text-red-600">{err}</p> : null}

      <div className="flex flex-wrap gap-2">
        <input
          className="min-w-[200px] flex-1 rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: colors.border }}
          placeholder="New item label"
          value={label}
          onChange={(e) => setLabel(e.target.value)}
        />
        <button
          type="button"
          disabled={busy}
          onClick={add}
          className="rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          style={{ backgroundColor: colors.primary }}
        >
          Add item
        </button>
      </div>

      <ul className="space-y-2">
        {ordered.map((k, i) => (
          <KitCatalogRow
            key={k.id}
            item={k}
            disabled={busy}
            onSaveLabel={(lab) => saveLabel(k.id, lab)}
            onDelete={() => del(k.id)}
            onMoveUp={() => move(i, -1)}
            onMoveDown={() => move(i, 1)}
          />
        ))}
      </ul>
    </div>
  );
}

function KitCatalogRow({
  item,
  disabled,
  onSaveLabel,
  onDelete,
  onMoveUp,
  onMoveDown,
}: {
  item: KitCatalogItem;
  disabled: boolean;
  onSaveLabel: (lab: string) => void;
  onDelete: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
}) {
  const [val, setVal] = useState(item.label);
  return (
    <li
      className="flex flex-wrap items-center gap-2 rounded-xl border px-3 py-2"
      style={{ borderColor: colors.border, backgroundColor: colors.card }}
    >
      <div className="flex flex-col gap-0.5">
        <button type="button" className="text-xs" onClick={onMoveUp}>
          ↑
        </button>
        <button type="button" className="text-xs" onClick={onMoveDown}>
          ↓
        </button>
      </div>
      <input
        className="min-w-[180px] flex-1 rounded border px-2 py-1.5 text-sm"
        style={{ borderColor: colors.border }}
        value={val}
        onChange={(e) => setVal(e.target.value)}
      />
      <button
        type="button"
        disabled={disabled}
        className="rounded border px-2 py-1 text-xs"
        style={{ borderColor: colors.border }}
        onClick={() => onSaveLabel(val.trim())}
      >
        Save
      </button>
      <span className="font-mono text-[10px] text-neutral-400">{item.id.slice(0, 8)}…</span>
      <button type="button" className="ml-auto text-xs text-red-700" onClick={onDelete}>
        Delete
      </button>
    </li>
  );
}
