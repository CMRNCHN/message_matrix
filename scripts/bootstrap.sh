#!/usr/bin/env bash
# First-time setup for Message Matrix stack.
# Usage: cp .env.example .env && edit .env && ./scripts/bootstrap.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source scripts/lib/docker.sh
ensure_docker

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

strip_url_host() {
  local u="$1"
  u="${u#https://}"
  u="${u#http://}"
  echo "$u"
}

set_env_var() {
  local key="$1" value="$2"
  if grep -q "^${key}=" .env 2>/dev/null; then
    if [[ "$(uname)" == Darwin ]]; then
      sed -i '' "s|^${key}=.*|${key}=${value}|" .env
    else
      sed -i "s|^${key}=.*|${key}=${value}|" .env
    fi
  else
    echo "${key}=${value}" >> .env
  fi
}

# Docker Compose cannot use bash ${VAR#https://}; keep hostnames in .env
SYNAPSE_PUBLIC_HOST="$(strip_url_host "$SYNAPSE_PUBLIC_URL")"
ELEMENT_PUBLIC_HOST="$(strip_url_host "$ELEMENT_PUBLIC_URL")"
INBOX_PUBLIC_HOST="$(strip_url_host "${INBOX_PUBLIC_URL:-https://app.${MATRIX_DOMAIN}}")"
set_env_var SYNAPSE_PUBLIC_HOST "$SYNAPSE_PUBLIC_HOST"
set_env_var ELEMENT_PUBLIC_HOST "$ELEMENT_PUBLIC_HOST"
set_env_var INBOX_PUBLIC_HOST "$INBOX_PUBLIC_HOST"

set -a
source .env
set +a

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
./scripts/render-caddy-config.sh

if [[ ! -f synapse/signing.key ]]; then
  echo "==> Generating Synapse signing key..."
  docker run --rm \
    -v "$ROOT/synapse:/data" \
    -e SYNAPSE_SERVER_NAME="$MATRIX_SERVER_NAME" \
    -e SYNAPSE_REPORT_STATS=no \
    matrixdotorg/synapse:latest generate

  ./scripts/render-synapse-config.sh
fi

cat > element/config.json <<EOF
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "${SYNAPSE_PUBLIC_URL}",
      "server_name": "${MATRIX_SERVER_NAME}"
    }
  },
  "default_server_name": "${MATRIX_SERVER_NAME}",
  "brand": "Message Matrix",
  "default_theme": "dark",
  "disable_custom_urls": true,
  "disable_guests": true,
  "disable_3pid_login": true,
  "show_labs_settings": true,
  "features": {
    "feature_pinning": "enable",
    "feature_thread": "enable",
    "feature_spaces": "enable"
  },
  "room_directory": {
    "servers": ["${MATRIX_SERVER_NAME}"]
  },
  "piwik": false
}
EOF

echo "==> Starting PostgreSQL..."
docker compose up -d postgres
sleep 5

echo "==> Starting core stack..."
docker compose up -d synapse element inbox-web caddy

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
