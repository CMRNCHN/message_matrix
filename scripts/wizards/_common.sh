#!/usr/bin/env bash
# Shared wizard completion — init bridge, register with Synapse, start container.

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../lib/bridges.sh"

wizard_finish_bridge() {
  local bridge_id="$1"
  local svc port mxid
  svc="$(bridge_service "$bridge_id")"
  port="$(bridge_port "$bridge_id")"
  mxid="$(bridge_mxid "$bridge_id")"

  wizard_step 99 "Applying configuration"
  wizard_info "Initializing bridge files..."
  "$WIZARD_ROOT/scripts/init-bridge.sh" "$bridge_id"

  bridge_enable "$bridge_id"
  wizard_ok "Enabled $(bridge_label "$bridge_id")"

  wizard_info "Updating Synapse registration..."
  "$WIZARD_ROOT/scripts/render-synapse-config.sh"

  wizard_info "Restarting Synapse..."
  (cd "$WIZARD_ROOT" && docker compose restart synapse)
  sleep 5

  wizard_info "Starting ${svc}..."
  (cd "$WIZARD_ROOT" && docker compose --profile bridges up -d "$svc")

  wizard_step 100 "Connect in Element"
  echo
  wizard_ok "Bridge container started on port ${port}"
  echo
  echo "  ${WIZ_BOLD}Finish setup in Element:${WIZ_RESET}"
  echo "    1. Open ${ELEMENT_PUBLIC_URL:-your Element URL}"
  echo "    2. Start a DM with ${WIZ_CYAN}${mxid}${WIZ_RESET}"
  echo "    3. Send: ${WIZ_BOLD}login${WIZ_RESET}"
  echo
  case "$bridge_id" in
    signal)    wizard_info "Scan the QR code with Signal → Linked devices" ;;
    telegram)  wizard_info "Enter phone number and verification code when prompted" ;;
    whatsapp)  wizard_info "Scan WhatsApp Web QR code from your phone" ;;
    imessage)  wizard_info "BlueBubbles must already be running on your Mac" ;;
    gvoice)    wizard_info "Follow Google Voice OAuth prompts in the bot chat" ;;
    gmessages) wizard_info "Pair with Google Messages via QR on your Android phone" ;;
    discord)   wizard_info "Paste your Discord user token or follow bot OAuth flow" ;;
    slack)     wizard_info "Use Slack OAuth or token login per bridge docs" ;;
    meta)      wizard_info "Log in to Messenger/Instagram when the bot prompts you" ;;
    snapchat)  wizard_warn "Experimental bridge — may require manual API endpoint config" ;;
  esac
  echo
}

wizard_run_or_source() {
  local bridge_id="$1"
  local wizard_script
  wizard_script="$(bridge_wizard_path "$bridge_id")"
  if [[ -f "$wizard_script" ]]; then
    # shellcheck disable=SC1090
    source "$wizard_script"
    "wizard_${bridge_id}" || "wizard_${bridge_id//-/_}"
  else
    wizard_err "No wizard for ${bridge_id}"
    exit 1
  fi
}
