#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_snapchat() {
  wizard_require_env
  wizard_header "Snapchat (experimental)" "Community reverse-engineered bridge — not production-ready"

  wizard_step 1 "Important limitations"
  wizard_warn "No official Snapchat API — bridge uses reverse-engineered endpoints"
  wizard_warn "Requires traffic capture / manual endpoint verification to function"
  wizard_info "Upstream: https://github.com/lalomorales22/snapchat-bridge"
  wizard_press_enter

  wizard_step 2 "Experimental opt-in"
  if ! wizard_confirm "Continue with experimental Snapchat setup?" "n"; then
    wizard_warn "Cancelled — recommended until upstream matures."
    exit 0
  fi

  wizard_require_docker
  wizard_err "Snapchat bridge is not bundled as a production image yet."
  wizard_info "Track progress in bridges/_placeholders/README.md"
  wizard_info "When ready: uncomment mautrix-snapchat in docker-compose.yml and rebuild"
  exit 1
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_snapchat
