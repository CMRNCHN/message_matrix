#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_gmessages() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Google Messages" "Bridge Android RCS/SMS via Google Messages pairing"

  wizard_step 1 "Prerequisites"
  wizard_info "Android phone with Google Messages as default SMS app"
  wizard_info "Alternative to Google Voice for carrier SMS/RCS"
  wizard_info "Docs: https://docs.mau.fi/bridges/go/gmessages/"
  wizard_press_enter

  wizard_step 2 "Confirm"
  if ! wizard_confirm "Set up Google Messages bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge gmessages
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_gmessages
