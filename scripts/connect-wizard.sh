#!/usr/bin/env bash
# Message Matrix Connection Wizard — interactive setup for all bridges.
# Usage: ./connect   or   ./scripts/connect-wizard.sh [bridge-id]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source scripts/lib/wizard-ui.sh
# shellcheck disable=SC1091
source scripts/lib/bridges.sh

run_bridge_wizard() {
  local id="$1"
  local wizard
  wizard="$(bridge_wizard_path "$id")"
  if [[ ! -f "$wizard" ]]; then
    wizard_err "Wizard not found: $wizard"
    exit 1
  fi
  bash "$wizard"
}

show_menu() {
  wizard_header "Connection Wizard" "Add messaging platforms to your private Matrix inbox"
  echo "  ${WIZ_BOLD}Available connections${WIZ_RESET}"
  echo

  local i=1
  local id
  for id in "${BRIDGE_IDS[@]}"; do
    local status icon label
    status="$(bridge_status "$id")"
    icon="$(wizard_status_icon "$status")"
    label="$(bridge_label "$id")"
    printf "  ${WIZ_BOLD}[%2d]${WIZ_RESET} %-28s %b\n" "$i" "$label" "$icon"
    ((i++)) || true
  done

  echo
  echo "  ${WIZ_BOLD}[ a ]${WIZ_RESET} Run wizards for all ${WIZ_DIM}not yet configured${WIZ_RESET} bridges"
  echo "  ${WIZ_BOLD}[ s ]${WIZ_RESET} Show status summary"
  echo "  ${WIZ_BOLD}[ q ]${WIZ_RESET} Quit"
  echo
}

show_status() {
  wizard_header "Connection Status"
  local id
  for id in "${BRIDGE_IDS[@]}"; do
    local status mxid
    status="$(bridge_status "$id")"
    mxid="$(bridge_mxid "$id" 2>/dev/null || echo "@bot:domain")"
    printf "  %-28s %b  ${WIZ_DIM}%s${WIZ_RESET}\n" "$(bridge_label "$id")" "$(wizard_status_icon "$status")" "$mxid"
  done
  echo
  wizard_press_enter
}

wizard_all_unconfigured() {
  local id ran=0
  for id in "${BRIDGE_IDS[@]}"; do
    if [[ "$(bridge_status "$id")" == "none" && "$id" != "snapchat" ]]; then
      echo
      run_bridge_wizard "$id" || wizard_warn "Skipped $(bridge_label "$id")"
      ran=1
    fi
  done
  if [[ "$ran" -eq 0 ]]; then
    wizard_ok "All production bridges are already configured or running."
  fi
}

main_menu() {
  wizard_require_env
  while true; do
    show_menu
    local choice=""
    read -r -p "  Choose a connection: " choice
    choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]' | xargs)"

    case "$choice" in
      q|quit|exit) echo; wizard_ok "Done."; exit 0 ;;
      s|status) show_status; continue ;;
      a|all) wizard_all_unconfigured; continue ;;
    esac

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      local idx=$((choice - 1))
      if [[ "$idx" -ge 0 && "$idx" -lt ${#BRIDGE_IDS[@]} ]]; then
        run_bridge_wizard "${BRIDGE_IDS[$idx]}"
        continue
      fi
    fi

    # Allow direct name: ./connect whatsapp
    if bridge_valid_id "$choice"; then
      run_bridge_wizard "$choice"
      continue
    fi

    wizard_warn "Invalid choice: $choice"
  done
}

# Direct invocation: ./connect telegram  |  ./connect status
if [[ $# -gt 0 ]]; then
  wizard_require_env
  if [[ "$1" == "status" || "$1" == "s" ]]; then
    show_status
    exit 0
  fi
  if bridge_valid_id "$1"; then
    run_bridge_wizard "$1"
  else
    wizard_err "Unknown bridge: $1"
    echo "Valid: ${BRIDGE_IDS[*]}"
    exit 1
  fi
else
  main_menu
fi
