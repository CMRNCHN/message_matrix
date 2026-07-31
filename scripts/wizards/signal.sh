#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_signal() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Signal" "Link Signal as a Matrix puppet via QR code"

  wizard_step 1 "Prerequisites"
  wizard_info "Signal mobile app with linked-device support"
  wizard_info "Core stack running (Synapse healthy)"
  wizard_press_enter

  wizard_step 2 "Confirm setup"
  wizard_info "No API keys needed — authentication happens via QR in Element."
  if ! wizard_confirm "Set up Signal bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge signal
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_signal
