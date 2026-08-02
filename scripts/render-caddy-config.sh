#!/usr/bin/env bash
# Render caddy/Caddyfile from template (TLS mode depends on .env).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Missing .env"
  exit 1
fi

set -a
source .env
set +a

TLS_DIRECTIVE=""
if [[ "${CADDY_TLS_MODE:-internal}" == "internal" ]]; then
  TLS_DIRECTIVE="local_certs"
fi

EMAIL_LINE=""
if [[ -n "${CADDY_ACME_EMAIL:-}" ]]; then
  EMAIL_LINE="email ${CADDY_ACME_EMAIL}"
fi

sed \
  -e "s|__CADDY_TLS_DIRECTIVE__|${TLS_DIRECTIVE}|" \
  -e "s|__CADDY_EMAIL_LINE__|${EMAIL_LINE}|" \
  caddy/Caddyfile.template > caddy/Caddyfile

echo "Rendered caddy/Caddyfile (TLS mode: ${CADDY_TLS_MODE:-internal})"
