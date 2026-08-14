#!/usr/bin/env bash
# Initialize a mautrix bridge: generate config, registration, patch settings.
# Usage: ./scripts/init-bridge.sh <bridge-id>

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source scripts/lib/bridges.sh

BRIDGE="${1:?bridge id required — run ./connect to list options}"

if ! bridge_valid_id "$BRIDGE"; then
  echo "Unknown bridge: $BRIDGE"
  echo "Valid: ${BRIDGE_IDS[*]}"
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Missing .env — run ./scripts/bootstrap.sh first"
  exit 1
fi

set -a
source .env
set +a

MATRIX_SERVER_NAME="${MATRIX_SERVER_NAME:?}"
ADMIN_MXID="@${SYNAPSE_ADMIN_USER}:${MATRIX_SERVER_NAME}"
SERVICE_NAME="$(bridge_service "$BRIDGE")"
BRIDGE_PORT="$(bridge_port "$BRIDGE")"
BRIDGE_DIR="$(bridge_dir "$BRIDGE")"
IMAGE="$(bridge_image "$BRIDGE")"

mkdir -p "$BRIDGE_DIR"

echo "==> Initializing $(bridge_label "$BRIDGE") in $BRIDGE_DIR"

if [[ "$IMAGE" == "local" ]]; then
  echo "Snapchat bridge must be built locally — see scripts/wizards/snapchat.sh"
  exit 1
fi

if [[ ! -f "$BRIDGE_DIR/config.yaml" ]]; then
  docker run --rm -v "$BRIDGE_DIR:/data" "$IMAGE"
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq is required to configure bridges."
  echo "  Install: brew install yq"
  echo "  Docs:    https://github.com/mikefarah/yq"
  exit 1
fi

echo "==> Patching $BRIDGE_DIR/config.yaml"
yq -i ".homeserver.address = \"http://synapse:8008\"" "$BRIDGE_DIR/config.yaml"
yq -i ".homeserver.domain = \"${MATRIX_SERVER_NAME}\"" "$BRIDGE_DIR/config.yaml"
yq -i ".appservice.address = \"http://${SERVICE_NAME}:${BRIDGE_PORT}\"" "$BRIDGE_DIR/config.yaml"
yq -i ".appservice.hostname = \"0.0.0.0\"" "$BRIDGE_DIR/config.yaml"
yq -i ".appservice.port = ${BRIDGE_PORT}" "$BRIDGE_DIR/config.yaml"
# Prefer SQLite so each bridge doesn't need a dedicated Postgres database.
yq -i '.database.type = "sqlite3-fk-wal"' "$BRIDGE_DIR/config.yaml"
yq -i '.database.uri = "file:/data/mautrix.db?_txlock=immediate"' "$BRIDGE_DIR/config.yaml"
# Replace example permission stubs with this homeserver + admin.
yq -i 'del(.bridge.permissions)' "$BRIDGE_DIR/config.yaml"
yq -i ".bridge.permissions.\"*\" = \"relay\"" "$BRIDGE_DIR/config.yaml"
yq -i ".bridge.permissions.\"${MATRIX_SERVER_NAME}\" = \"user\"" "$BRIDGE_DIR/config.yaml"
yq -i ".bridge.permissions.\"${ADMIN_MXID}\" = \"admin\"" "$BRIDGE_DIR/config.yaml"
yq -i ".encryption.allow = false" "$BRIDGE_DIR/config.yaml"
yq -i ".encryption.default = false" "$BRIDGE_DIR/config.yaml"

case "$BRIDGE" in
  telegram)
    if [[ -n "${TELEGRAM_API_ID:-}" && -n "${TELEGRAM_API_HASH:-}" ]]; then
      yq -i ".telegram.api_id = ${TELEGRAM_API_ID}" "$BRIDGE_DIR/config.yaml"
      yq -i ".telegram.api_hash = \"${TELEGRAM_API_HASH}\"" "$BRIDGE_DIR/config.yaml"
    fi
    ;;
  imessage)
    yq -i ".imessage.platform = \"bluebubbles\"" "$BRIDGE_DIR/config.yaml"
    yq -i ".imessage.bluebubbles_url = \"${BLUEBUBBLES_URL:-http://host.docker.internal:1234}\"" "$BRIDGE_DIR/config.yaml"
    yq -i ".imessage.bluebubbles_password = \"${BLUEBUBBLES_PASSWORD:-}\"" "$BRIDGE_DIR/config.yaml"
    ;;
esac

if [[ ! -f "$BRIDGE_DIR/registration.yaml" ]]; then
  echo "==> Generating registration.yaml"
  if ! docker run --rm \
    -v "$BRIDGE_DIR:/data" \
    --entrypoint "/usr/bin/mautrix-${BRIDGE}" \
    "$IMAGE" \
    -c /data/config.yaml \
    -r /data/registration.yaml \
    -g; then
    # Older images use a different flag layout; try once more without -c/-r.
    docker run --rm \
      -v "$BRIDGE_DIR:/data" \
      --entrypoint "/usr/bin/mautrix-${BRIDGE}" \
      "$IMAGE" \
      -g || true
  fi
fi

if [[ ! -f "$BRIDGE_DIR/registration.yaml" ]]; then
  echo "ERROR: registration.yaml not generated for $BRIDGE"
  echo "  Check $BRIDGE_DIR/config.yaml (homeserver.address / database.uri) and retry."
  exit 1
fi

echo "==> $(bridge_label "$BRIDGE") ready"
