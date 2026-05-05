"use client";

import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { useEffect } from "react";
import type { HighlightTag } from "@/lib/catalog/highlight-tags";
import { pillText } from "@/lib/catalog/highlight-tags";
import { PhosphorIcon } from "@/components/phosphor-icon";
import {
  highlightGlyphOnGradient,
  highlightPhosphorIcon,
} from "@/lib/highlight/highlight-phosphor";
import { gradientStyle } from "@/lib/highlight/highlight-style";
import { colors } from "@/lib/theme/colors";

export function HighlightDetailModal({
  tag,
  open,
  onClose,
}: {
  tag: HighlightTag | null;
  open: boolean;
  onClose: () => void;
}) {
  const reduce = useReducedMotion();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  const body = tag?.body.trim() ?? "";
  const fallback =
    "No extra details yet — add detail text for this highlight in Admin → Highlights.";

  return (
    <AnimatePresence>
      {open && tag ? (
        <motion.div
          key="backdrop"
          className="fixed inset-0 z-50 flex transform-gpu items-end justify-center p-0 pb-0 pt-10 perspective-[880px] max-sm:pb-0 max-sm:pt-8 sm:items-center sm:p-6"
          role="dialog"
          aria-modal="true"
          aria-labelledby="highlight-modal-title"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: reduce ? 0.12 : 0.25 }}
        >
          <motion.button
            type="button"
            className="absolute inset-0 bg-black/45"
            aria-label="Close"
            onClick={onClose}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          />
          <motion.div
            className="relative mx-0 w-full max-h-[min(92dvh,calc(100dvh-env(safe-area-inset-bottom)-0.5rem))] overflow-hidden overflow-y-auto rounded-t-[1.75rem] border shadow-2xl sm:mx-auto sm:max-h-[min(70vh,560px)] sm:w-full sm:max-w-lg sm:rounded-2xl"
            style={{
              borderColor: colors.border,
              backgroundColor: colors.card,
            }}
            initial={
              reduce
                ? { opacity: 0 }
                : { opacity: 0, y: 40 }
            }
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={
              reduce
                ? { opacity: 0 }
                : { opacity: 0, y: 24 }
            }
            transition={{ type: "spring", stiffness: 380, damping: 26 }}
          >
            <div
              className="flex items-start gap-3 border-b px-4 py-4 sm:px-5"
              style={{
                borderColor: colors.border,
                ...gradientStyle(tag.iconKey),
              }}
            >
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-white/15 p-1 drop-shadow backdrop-blur-[2px]">
                <PhosphorIcon
                  icon={highlightPhosphorIcon(tag.iconKey)}
                  size="xl"
                  weight="fill"
                  color={highlightGlyphOnGradient}
                />
              </span>
              <div className="min-w-0 flex-1">
                <h2
                  id="highlight-modal-title"
                  className="text-lg font-bold leading-snug text-white drop-shadow"
                >
                  {tag.title.trim() || pillText(tag)}
                </h2>
                {tag.title.trim() && pillText(tag) !== tag.title.trim() ? (
                  <p className="mt-0.5 text-sm font-semibold text-white/90">
                    {pillText(tag)}
                  </p>
                ) : null}
              </div>
              <button
                type="button"
                onClick={onClose}
                className="inline-flex min-h-11 min-w-11 shrink-0 touch-manipulation items-center justify-center rounded-full bg-black/20 text-xl font-light leading-none text-white hover:bg-black/30"
                aria-label="Close"
              >
                ×
              </button>
            </div>
            <motion.div
              className="px-4 py-4 text-sm leading-relaxed sm:px-5 pb-[max(1.25rem,env(safe-area-inset-bottom))]"
              style={{ color: colors.textPrimary }}
              initial={reduce ? false : { opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: reduce ? 0 : 0.08 }}
            >
              {body.length > 0 ? body : fallback}
            </motion.div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
