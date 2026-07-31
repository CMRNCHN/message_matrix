#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_discord() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Discord" "Puppet your Discord account into Matrix"

  wizard_step 1 "Prerequisites"
  wizard_info "Discord account — bridge uses user token or browser login flow"
  wizard_warn "Automating Discord may violate ToS — use at your own risk"
  wizard_info "Docs: https://docs.mau.fi/bridges/python/discord/"
  wizard_press_enter

  wizard_step 2 "Confirm"
  if ! wizard_confirm "Set up Discord bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge discord
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_discord
