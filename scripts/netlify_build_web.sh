#!/usr/bin/env bash
# Netlify injects secrets into the shell environment; they are NOT substituted
# into netlify.toml command strings.
#
# Use --dart-define-from-file JSON (not shell --dart-define=...) so JWT / +/punct
# in SUPABASE_ANON_KEY never breaks parsing on the Flutter CLI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "ERROR: Set SUPABASE_URL and SUPABASE_ANON_KEY in Netlify → Environment variables (build)." >&2
  exit 1
fi

if [[ -z "${RAZORPAY_KEY_ID:-}" && -z "${RAZORPAY_API_KEY:-}" ]]; then
  echo "WARN: RAZORPAY_KEY_ID / RAZORPAY_API_KEY not set — Razorpay checkout disabled on web until set." >&2
fi

FLUTTER_SDK="${ROOT}/.flutter-sdk"
if [[ ! -x "${FLUTTER_SDK}/bin/flutter" ]]; then
  rm -rf "${FLUTTER_SDK}"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_SDK}"
fi
export PATH="${FLUTTER_SDK}/bin:${PATH}"

flutter config --enable-web --no-analytics
flutter precache --web
flutter pub get

python3 - <<'PY'
import json, os

url = os.environ["SUPABASE_URL"].strip()
key = os.environ["SUPABASE_ANON_KEY"].strip()
if len(url) < 8:
    raise SystemExit("SUPABASE_URL invalid (too short)")
if len(key) < 30:
    raise SystemExit("SUPABASE_ANON_KEY invalid (too short)")

defines = {"SUPABASE_URL": url, "SUPABASE_ANON_KEY": key}
rzp = (
    os.environ.get("RAZORPAY_KEY_ID", "").strip()
    or os.environ.get("RAZORPAY_API_KEY", "").strip()
)
if rzp:
    defines["RAZORPAY_KEY_ID"] = rzp

with open("dart_defines.json", "w", encoding="utf-8") as f:
    json.dump(defines, f, ensure_ascii=False)

env_lines = [f"SUPABASE_URL={url}", f"SUPABASE_ANON_KEY={key}"]
if rzp:
    env_lines.append(f"RAZORPAY_KEY_ID={rzp}")
with open(".env", "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(env_lines) + "\n")
PY

flutter build web --release \
  --dart-define-from-file=dart_defines.json
