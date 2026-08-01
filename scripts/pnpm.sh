#!/usr/bin/env bash
# Run pnpm without a global install (uses pinned version via npx).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec npx --yes pnpm@9.15.4 --dir "$ROOT" "$@"
