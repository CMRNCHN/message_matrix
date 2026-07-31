#!/usr/bin/env bash
# Render synapse/homeserver.yaml from template + enabled bridge registrations.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source scripts/lib/bridges.sh

if [[ ! -f .env ]]; then
  echo "Missing .env"
  exit 1
fi

set -a
source .env
set +a

FEDERATION_BLOCK=""
if [[ "${DISABLE_FEDERATION:-true}" == "true" ]]; then
  FEDERATION_BLOCK=$'federation_domain_whitelist: []\nallow_federation: false'
else
  FEDERATION_BLOCK="allow_federation: true"
fi
export FEDERATION_BLOCK

envsubst '${MATRIX_SERVER_NAME} ${SYNAPSE_PUBLIC_URL} ${ELEMENT_PUBLIC_URL} ${POSTGRES_PASSWORD} ${SYNAPSE_REGISTRATION_SHARED_SECRET} ${FEDERATION_BLOCK}' \
  < synapse/homeserver.yaml.template > synapse/homeserver.yaml.tmp

{
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "__APP_SERVICE_CONFIG_FILES__" ]]; then
      if [[ -f "$BRIDGE_ENABLED_FILE" ]] && [[ -s "$BRIDGE_ENABLED_FILE" ]]; then
        echo "app_service_config_files:"
        while IFS= read -r bridge_id; do
          [[ -z "$bridge_id" ]] && continue
          if [[ -f "$(bridge_dir "$bridge_id")/registration.yaml" ]]; then
            echo "  - /data/bridges/${bridge_id}/registration.yaml"
          fi
        done < "$BRIDGE_ENABLED_FILE"
      else
        echo "# No bridges enabled — run ./connect to add connections"
      fi
    else
      echo "$line"
    fi
  done < synapse/homeserver.yaml.tmp
} > synapse/homeserver.yaml

rm -f synapse/homeserver.yaml.tmp

count=0
[[ -f "$BRIDGE_ENABLED_FILE" ]] && count=$(grep -cve '^$' "$BRIDGE_ENABLED_FILE" 2>/dev/null || echo 0)
echo "Rendered synapse/homeserver.yaml (${count} enabled bridges)"
