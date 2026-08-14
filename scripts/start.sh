#!/usr/bin/env bash
# Start Message Matrix: OrbStack/Docker → stack (+ enabled bridges) → open inbox.
# Usage:
#   ./start                 # start everything and open the unified inbox
#   ./start --element       # open Element instead of the inbox
#   ./start --no-open       # start services only
#   ./start --desktop       # prefer the Mac desktop app if installed

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Finder / double-click launches often lack Homebrew + OrbStack on PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.orbstack/bin:${PATH}"

# shellcheck disable=SC1091
source scripts/lib/docker.sh
# shellcheck disable=SC1091
source scripts/lib/bridges.sh

OPEN_GUI=1
GUI_TARGET=inbox   # inbox | element | desktop

usage() {
  cat <<'EOF'
Usage: ./start [options]

  (default)     Start Docker/OrbStack, bring up the stack, open the inbox
  --element     Open Element Web instead of the unified inbox
  --desktop     Open the Message Matrix Mac app if installed; else inbox URL
  --no-open     Do not open a browser/app
  -h, --help    Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --element) OPEN_GUI=1; GUI_TARGET=element; shift ;;
    --desktop) OPEN_GUI=1; GUI_TARGET=desktop; shift ;;
    --no-open) OPEN_GUI=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example and run ./scripts/bootstrap.sh first."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

INBOX_URL="${INBOX_PUBLIC_URL:-https://app.matrix.local}"
ELEMENT_URL="${ELEMENT_PUBLIC_URL:-https://chat.matrix.local}"

echo "==> Message Matrix"
ensure_docker

echo "==> Starting core stack"
docker compose up -d

ENABLED_SERVICES=()
if [[ -f "$BRIDGE_ENABLED_FILE" ]]; then
  while IFS= read -r bridge_id || [[ -n "$bridge_id" ]]; do
    [[ -z "${bridge_id// }" ]] && continue
    [[ "$bridge_id" == \#* ]] && continue
    if bridge_valid_id "$bridge_id"; then
      ENABLED_SERVICES+=("$(bridge_service "$bridge_id")")
    fi
  done < "$BRIDGE_ENABLED_FILE"
fi

if [[ ${#ENABLED_SERVICES[@]} -gt 0 ]]; then
  echo "==> Starting enabled bridges: ${ENABLED_SERVICES[*]}"
  docker compose --profile bridges up -d "${ENABLED_SERVICES[@]}"
fi

wait_healthy() {
  local service="$1"
  local container="message-matrix-${service}-1"
  local i health has_hc
  for i in $(seq 1 45); do
    health="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || echo missing)"
    has_hc="$(docker inspect --format='{{if .State.Health}}yes{{else}}no{{end}}' "$container" 2>/dev/null || echo no)"
    if [[ "$has_hc" == "yes" && "$health" == "healthy" ]]; then
      return 0
    fi
    if [[ "$has_hc" == "no" && "$health" == "running" ]]; then
      return 0
    fi
    sleep 1
  done
  echo "    warning: ${service} not ready yet (last status: ${health:-unknown})"
  return 1
}

echo "==> Waiting for services"
wait_healthy postgres || true
wait_healthy synapse || true
wait_healthy caddy || true

echo
echo "  Homeserver  ${SYNAPSE_PUBLIC_URL:-https://matrix.local}"
echo "  Inbox       ${INBOX_URL}"
echo "  Element     ${ELEMENT_URL}"
if [[ ${#ENABLED_SERVICES[@]} -gt 0 ]]; then
  echo "  Bridges     ${ENABLED_SERVICES[*]}"
else
  echo "  Bridges     (none — run ./connect to add)"
fi
echo

find_desktop_app() {
  local candidates=(
    "/Applications/Message Matrix.app"
    "${HOME}/Applications/Message Matrix.app"
    "${ROOT}/apps/inbox-desktop/src-tauri/target/release/bundle/macos/Message Matrix.app"
    "${ROOT}/apps/inbox-desktop/src-tauri/target/debug/bundle/macos/Message Matrix.app"
  )
  local p
  for p in "${candidates[@]}"; do
    if [[ -d "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

open_gui() {
  case "$GUI_TARGET" in
    element)
      echo "==> Opening Element"
      open "$ELEMENT_URL"
      ;;
    desktop)
      local app
      if app="$(find_desktop_app)"; then
        echo "==> Opening Message Matrix app"
        open "$app"
      else
        echo "==> Desktop app not installed — opening inbox in browser"
        echo "    (build later with: npm run build:desktop)"
        open "$INBOX_URL"
      fi
      ;;
    *)
      echo "==> Opening inbox"
      open "$INBOX_URL"
      ;;
  esac
}

if [[ "$OPEN_GUI" -eq 1 ]]; then
  # Give Caddy a moment after "healthy" before the browser hits TLS.
  sleep 1
  open_gui
fi

echo "Done. Stop later with: ./stop"
