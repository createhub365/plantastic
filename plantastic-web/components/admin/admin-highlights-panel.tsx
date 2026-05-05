"use client";

import { useRouter } from "next/navigation";
import { startTransition, useEffect, useMemo, useState } from "react";
import {
  adminCreateHighlight,
  adminDeleteHighlight,
  adminReorderHighlights,
  adminUpdateHighlight,
} from "@/lib/admin/catalog-actions";
import { HIGHLIGHT_ICON_KEYS } from "@/lib/catalog/highlight-icon-keys";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import { colors } from "@/lib/theme/colors";

export function AdminHighlightsPanel({ initial }: { initial: HighlightTag[] }) {
  const router = useRouter();
  const [items, setItems] = useState(initial);
  const [title, setTitle] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => setItems(initial), [initial]);

  const ordered = useMemo(
    () => [...items].sort((a, b) => a.sortOrder - b.sortOrder),
    [items],
  );

  const persistOrder = (next: HighlightTag[]) => {
    setBusy(true);
    startTransition(() => {
      void adminReorderHighlights(next.map((h) => h.id)).then((r) => {
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
    const t = title.trim();
    if (t.length < 2) return;
    setBusy(true);
    startTransition(() => {
      void adminCreateHighlight({ title: t }).then((r) => {
        setBusy(false);
        setTitle("");
        if (r.error) setErr(r.error);
        router.refresh();
      });
    });
  };

  return (
    <div className="space-y-4">
      <p className="text-sm" style={{ color: colors.textSecondary }}>
        Shopper highlight pills — same fields as Flutter (
        <code className="text-xs">highlight_tags</code>).
      </p>
      {err ? <p className="text-sm text-red-600">{err}</p> : null}

      <div className="flex flex-wrap gap-2">
        <input
          className="min-w-[200px] flex-1 rounded-lg border px-3 py-2 text-sm"
          style={{ borderColor: colors.border }}
          placeholder="New highlight title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        <button
          type="button"
          disabled={busy}
          onClick={add}
          className="rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          style={{ backgroundColor: colors.primary }}
        >
          Add
        </button>
      </div>

      <ul className="space-y-2">
        {ordered.map((h, i) => (
          <HighlightRow
            key={h.id}
            tag={h}
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

function HighlightRow({
  tag,
  disabled,
  onMoveUp,
  onMoveDown,
  onSaved,
  onError,
}: {
  tag: HighlightTag;
  disabled: boolean;
  onMoveUp: () => void;
  onMoveDown: () => void;
  onSaved: () => void;
  onError: (s: string | null) => void;
}) {
  const [title, setTitle] = useState(tag.title);
  const [label, setLabel] = useState(tag.label);
  const [iconKey, setIconKey] = useState(tag.iconKey);
  const [body, setBody] = useState(tag.body);

  const iconOptions = Array.from(new Set([iconKey, ...HIGHLIGHT_ICON_KEYS]));

  const save = () => {
    onError(null);
    startTransition(() => {
      void adminUpdateHighlight({
        id: tag.id,
        title: title.trim(),
        label: label.trim(),
        iconKey,
        body,
      }).then((r) => {
        if (r.error) onError(r.error);
        onSaved();
      });
    });
  };

  const del = () => {
    if (!window.confirm("Delete this highlight?")) return;
    onError(null);
    startTransition(() => {
      void adminDeleteHighlight(tag.id).then((r) => {
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
      <div className="flex flex-wrap items-start gap-2">
        <div className="flex flex-col">
          <button type="button" className="text-xs" onClick={onMoveUp}>
            ↑
          </button>
          <button type="button" className="text-xs" onClick={onMoveDown}>
            ↓
          </button>
        </div>
        <div className="min-w-0 flex-1 space-y-2">
          <input
            className="w-full rounded border px-2 py-1.5 text-sm font-semibold"
            style={{ borderColor: colors.border }}
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
          <input
            className="w-full rounded border px-2 py-1.5 text-xs"
            style={{ borderColor: colors.border }}
            placeholder="Pill label (optional)"
            value={label}
            onChange={(e) => setLabel(e.target.value)}
          />
          <select
            className="w-full rounded border px-2 py-1.5 text-sm"
            style={{ borderColor: colors.border }}
            value={iconKey}
            onChange={(e) => setIconKey(e.target.value)}
          >
            {iconOptions.map((k) => (
              <option key={k} value={k}>
                {k}
              </option>
            ))}
          </select>
          <textarea
            className="w-full rounded border px-2 py-1.5 text-sm"
            style={{ borderColor: colors.border }}
            rows={3}
            placeholder="Detail text (modal)"
            value={body}
            onChange={(e) => setBody(e.target.value)}
          />
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
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
        <span className="font-mono text-[10px] text-neutral-400">{tag.id}</span>
      </div>
    </li>
  );
}
