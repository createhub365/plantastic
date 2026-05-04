#!/usr/bin/env bash
# Netlify injects secrets into the shell environment; they are NOT substituted
# into netlify.toml command strings. Write .env + dart-define from bash here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "ERROR: Set SUPABASE_URL and SUPABASE_ANON_KEY in Netlify → Environment variables (build)." >&2
  exit 1
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

{
  printf 'SUPABASE_URL=%s\n' "${SUPABASE_URL}"
  printf 'SUPABASE_ANON_KEY=%s\n' "${SUPABASE_ANON_KEY}"
} > .env

flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
