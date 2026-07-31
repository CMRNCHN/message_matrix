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

if command -v yq >/dev/null 2>&1; then
  yq -i ".homeserver.address = \"http://synapse:8008\"" "$BRIDGE_DIR/config.yaml"
  yq -i ".homeserver.domain = \"${MATRIX_SERVER_NAME}\"" "$BRIDGE_DIR/config.yaml"
  yq -i ".appservice.address = \"http://${SERVICE_NAME}:${BRIDGE_PORT}\"" "$BRIDGE_DIR/config.yaml"
  yq -i ".appservice.hostname = \"0.0.0.0\"" "$BRIDGE_DIR/config.yaml"
  yq -i ".appservice.port = ${BRIDGE_PORT}" "$BRIDGE_DIR/config.yaml"
  yq -i ".bridge.permissions.\"${ADMIN_MXID}\" = \"admin\"" "$BRIDGE_DIR/config.yaml"
  yq -i ".encryption.allow = false" "$BRIDGE_DIR/config.yaml"
  yq -i ".encryption.default = false" "$BRIDGE_DIR/config.yaml"
else
  echo "Install yq for automatic config patching: https://github.com/mikefarah/yq"
fi

case "$BRIDGE" in
  telegram)
    if [[ -n "${TELEGRAM_API_ID:-}" && -n "${TELEGRAM_API_HASH:-}" ]] && command -v yq >/dev/null 2>&1; then
      yq -i ".telegram.api_id = ${TELEGRAM_API_ID}" "$BRIDGE_DIR/config.yaml"
      yq -i ".telegram.api_hash = \"${TELEGRAM_API_HASH}\"" "$BRIDGE_DIR/config.yaml"
    fi
    ;;
  imessage)
    if command -v yq >/dev/null 2>&1; then
      yq -i ".imessage.platform = \"bluebubbles\"" "$BRIDGE_DIR/config.yaml"
      yq -i ".imessage.bluebubbles_url = \"${BLUEBUBBLES_URL:-http://host.docker.internal:1234}\"" "$BRIDGE_DIR/config.yaml"
      yq -i ".imessage.bluebubbles_password = \"${BLUEBUBBLES_PASSWORD:-}\"" "$BRIDGE_DIR/config.yaml"
    fi
    ;;
esac

if [[ ! -f "$BRIDGE_DIR/registration.yaml" ]]; then
  docker run --rm -v "$BRIDGE_DIR:/data" --entrypoint "/usr/bin/mautrix-${BRIDGE}" "$IMAGE" -g 2>/dev/null || \
  docker run --rm -v "$BRIDGE_DIR:/data" "$IMAGE" --generate-registration 2>/dev/null || \
  docker run --rm -v "$BRIDGE_DIR:/data" --entrypoint "/usr/bin/mautrix-${BRIDGE}" "$IMAGE" -registration "$BRIDGE_DIR/registration.yaml" 2>/dev/null || true
fi

if [[ ! -f "$BRIDGE_DIR/registration.yaml" ]]; then
  echo "ERROR: registration.yaml not generated for $BRIDGE"
  exit 1
fi

echo "==> $(bridge_label "$BRIDGE") ready"
