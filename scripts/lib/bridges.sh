#!/usr/bin/env bash
# Bridge registry — metadata for all supported Message Matrix connections.

BRIDGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIDGE_ENABLED_FILE="$BRIDGE_ROOT/bridges/.enabled"

# All connectable platforms (order = menu order)
BRIDGE_IDS=(
  signal
  telegram
  whatsapp
  imessage
  gvoice
  gmessages
  discord
  slack
  meta
  snapchat
)

bridge_label() {
  case "$1" in
    signal)    echo "Signal" ;;
    telegram)  echo "Telegram" ;;
    whatsapp)  echo "WhatsApp" ;;
    imessage)  echo "iMessage (BlueBubbles)" ;;
    gvoice)    echo "Google Voice" ;;
    gmessages) echo "Google Messages (RCS/SMS)" ;;
    discord)   echo "Discord" ;;
    slack)     echo "Slack" ;;
    meta)      echo "Meta (Messenger / Instagram)" ;;
    snapchat)  echo "Snapchat (experimental)" ;;
    *)         echo "$1" ;;
  esac
}

bridge_service() {
  case "$1" in
    signal)    echo "mautrix-signal" ;;
    telegram)  echo "mautrix-telegram" ;;
    whatsapp)  echo "mautrix-whatsapp" ;;
    imessage)  echo "mautrix-imessage" ;;
    gvoice)    echo "mautrix-gvoice" ;;
    gmessages) echo "mautrix-gmessages" ;;
    discord)   echo "mautrix-discord" ;;
    slack)     echo "mautrix-slack" ;;
    meta)      echo "mautrix-meta" ;;
    snapchat)  echo "mautrix-snapchat" ;;
  esac
}

bridge_port() {
  case "$1" in
    telegram)  echo 29317 ;;
    whatsapp)  echo 29318 ;;
    imessage)  echo 29319 ;;
    meta)      echo 29319 ;;
    discord)   echo 29334 ;;
    slack)     echo 29335 ;;
    gmessages) echo 29336 ;;
    gvoice)    echo 29338 ;;
    signal)    echo 29328 ;;
    snapchat)  echo 29337 ;;
  esac
}

bridge_bot_localpart() {
  case "$1" in
    signal)    echo "signalbot" ;;
    telegram)  echo "telegrambot" ;;
    whatsapp)  echo "whatsappbot" ;;
    imessage)  echo "imessagebot" ;;
    gvoice)    echo "gvoicebot" ;;
    gmessages) echo "gmessagesbot" ;;
    discord)   echo "discordbot" ;;
    slack)     echo "slackbot" ;;
    meta)      echo "metabot" ;;
    snapchat)  echo "snapchatbot" ;;
  esac
}

bridge_image() {
  case "$1" in
    snapchat) echo "local" ;;
    *)        echo "dock.mau.dev/mautrix/${1}:latest" ;;
  esac
}

bridge_experimental() {
  case "$1" in
    snapchat) return 0 ;;
    *)        return 1 ;;
  esac
}

bridge_wizard_path() {
  echo "$BRIDGE_ROOT/scripts/wizards/${1}.sh"
}

bridge_dir() {
  echo "$BRIDGE_ROOT/bridges/${1}"
}

bridge_is_enabled() {
  local id="$1"
  [[ -f "$BRIDGE_ENABLED_FILE" ]] && grep -qx "$id" "$BRIDGE_ENABLED_FILE" 2>/dev/null
}

bridge_enable() {
  local id="$1"
  mkdir -p "$(dirname "$BRIDGE_ENABLED_FILE")"
  touch "$BRIDGE_ENABLED_FILE"
  grep -qx "$id" "$BRIDGE_ENABLED_FILE" 2>/dev/null || echo "$id" >> "$BRIDGE_ENABLED_FILE"
}

bridge_disable() {
  local id="$1"
  [[ -f "$BRIDGE_ENABLED_FILE" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  grep -vx "$id" "$BRIDGE_ENABLED_FILE" > "$tmp" || true
  mv "$tmp" "$BRIDGE_ENABLED_FILE"
}

bridge_is_configured() {
  local id="$1"
  [[ -f "$(bridge_dir "$id")/registration.yaml" && -f "$(bridge_dir "$id")/config.yaml" ]]
}

bridge_is_running() {
  local id="$1"
  local svc
  svc="$(bridge_service "$id")"
  cd "$BRIDGE_ROOT"
  docker compose ps --status running --services 2>/dev/null | grep -qx "$svc"
}

bridge_status() {
  local id="$1"
  if bridge_is_running "$id"; then
    echo "running"
  elif bridge_is_enabled "$id" && bridge_is_configured "$id"; then
    echo "configured"
  elif bridge_experimental "$id"; then
    echo "experimental"
  else
    echo "none"
  fi
}

bridge_list_enabled() {
  if [[ -f "$BRIDGE_ENABLED_FILE" ]]; then
    cat "$BRIDGE_ENABLED_FILE"
  fi
}

bridge_mxid() {
  local id="$1"
  local lp
  lp="$(bridge_bot_localpart "$id")"
  echo "@${lp}:${MATRIX_SERVER_NAME}"
}

bridge_valid_id() {
  local id="$1"
  local bid
  for bid in "${BRIDGE_IDS[@]}"; do
    [[ "$bid" == "$id" ]] && return 0
  done
  return 1
}
