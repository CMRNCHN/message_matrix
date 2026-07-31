#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_gvoice() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Google Voice" "Bridge Google Voice SMS/MMS into Matrix"

  wizard_step 1 "Account type"
  wizard_info "Workspace Google accounts: simpler OAuth flow"
  wizard_warn "Consumer Gmail accounts may require Electron headless on the bridge host"
  wizard_info "Docs: https://docs.mau.fi/bridges/go/gvoice/"
  wizard_press_enter

  wizard_step 2 "Confirm"
  wizard_set_env "GVOICE_ENABLED" "true"
  if ! wizard_confirm "Set up Google Voice bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge gvoice
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_gvoice
