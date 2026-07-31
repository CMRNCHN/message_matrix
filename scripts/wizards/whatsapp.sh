#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_whatsapp() {
  wizard_require_env
  wizard_require_docker
  wizard_header "WhatsApp" "Bridge WhatsApp via WhatsApp Web QR pairing"

  wizard_step 1 "Prerequisites"
  wizard_info "WhatsApp on your phone (must stay connected for bridging)"
  wizard_info "Optional: dedicated phone/SIM or Android VM for 24/7 uptime"
  wizard_warn "Using your primary phone means the bridge drops if WhatsApp logs out"
  wizard_press_enter

  wizard_step 2 "Bridge mode"
  wizard_info "Default: standard WhatsApp Web pairing (scan QR in Element bot chat)"
  local use_vm=""
  wizard_prompt use_vm "Using a virtual Android phone? (y/N — just press Enter for normal phone)" "n"

  wizard_step 3 "Confirm"
  if ! wizard_confirm "Set up WhatsApp bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge whatsapp
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_whatsapp
