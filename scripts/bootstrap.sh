#!/usr/bin/env bash
# First-time setup for Message Matrix stack.
# Usage: cp .env.example .env && edit .env && ./scripts/bootstrap.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Copy .env.example to .env and configure it first."
  exit 1
fi

set -a
source .env
set +a

: "${MATRIX_SERVER_NAME:?}"
: "${SYNAPSE_PUBLIC_URL:?}"
: "${ELEMENT_PUBLIC_URL:?}"
: "${POSTGRES_PASSWORD:?}"
: "${SYNAPSE_REGISTRATION_SHARED_SECRET:?}"
: "${SYNAPSE_ADMIN_USER:?}"
: "${SYNAPSE_ADMIN_PASSWORD:?}"

echo "==> Message Matrix bootstrap"
echo "    Server: ${MATRIX_SERVER_NAME}"
echo "    Synapse: ${SYNAPSE_PUBLIC_URL}"
echo "    Element: ${ELEMENT_PUBLIC_URL}"

FEDERATION_BLOCK=""
if [[ "${DISABLE_FEDERATION:-true}" == "true" ]]; then
  FEDERATION_BLOCK=$'federation_domain_whitelist: []\nallow_federation: false'
else
  FEDERATION_BLOCK="allow_federation: true"
fi
export FEDERATION_BLOCK

mkdir -p synapse element bridges bridges/_placeholders
touch bridges/.enabled

./scripts/render-synapse-config.sh

if [[ ! -f synapse/signing.key ]]; then
  echo "==> Generating Synapse signing key..."
  docker run --rm \
    -v "$ROOT/synapse:/data" \
    matrixdotorg/synapse:latest generate \
    --server-name "$MATRIX_SERVER_NAME" \
    --config-path /data/homeserver.yaml \
    --report-stats no

  ./scripts/render-synapse-config.sh
fi

sed \
  -e "s|example.com|${MATRIX_SERVER_NAME}|g" \
  -e "s|https://matrix.example.com|${SYNAPSE_PUBLIC_URL}|g" \
  element/config.json.template > element/config.json

echo "==> Starting PostgreSQL..."
docker compose up -d postgres
sleep 5

echo "==> Starting core stack..."
docker compose up -d synapse element caddy

echo "==> Waiting for Synapse..."
for _ in $(seq 1 30); do
  if docker compose exec -T synapse curl -fsS http://localhost:8008/health >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "==> Creating admin @${SYNAPSE_ADMIN_USER}:${MATRIX_SERVER_NAME}..."
docker compose exec -T synapse register_new_matrix_user \
  -c /data/homeserver.yaml \
  -u "$SYNAPSE_ADMIN_USER" \
  -p "$SYNAPSE_ADMIN_PASSWORD" \
  -a \
  http://localhost:8008 || echo "Admin user may already exist."

cat <<EOF

Bootstrap complete.

  Element:  ${ELEMENT_PUBLIC_URL}
  Synapse:  ${SYNAPSE_PUBLIC_URL}
  Admin:    @${SYNAPSE_ADMIN_USER}:${MATRIX_SERVER_NAME}

Next:
  1. Trust Caddy internal CA (LAN) or configure DNS + CADDY_ACME_EMAIL.
  2. Open unified inbox:  ${INBOX_PUBLIC_URL:-https://app.example.com}
  3. Connect platforms:  ./connect

EOF
