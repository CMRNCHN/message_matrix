#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_meta() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Meta (Messenger / Instagram)" "Bridge Meta messaging into Matrix"

  wizard_step 1 "Choose network"
  wizard_info "Supports Facebook Messenger and Instagram DMs"
  wizard_info "You will authenticate in Element after the bridge starts"
  wizard_info "Docs: https://docs.mau.fi/bridges/go/meta/"
  echo

  local network=""
  wizard_prompt network "Primary network (messenger / instagram)" "messenger"
  wizard_set_env "META_NETWORK" "$network"

  wizard_step 2 "Confirm"
  if ! wizard_confirm "Set up Meta bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge meta
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_meta
