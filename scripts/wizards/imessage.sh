#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_imessage() {
  wizard_require_env
  wizard_require_docker
  wizard_header "iMessage (BlueBubbles)" "Bridge iMessage through a BlueBubbles server on macOS"

  wizard_step 1 "BlueBubbles server"
  wizard_info "Install BlueBubbles on a Mac signed into iMessage"
  wizard_info "Enable REST API and set a server password in BlueBubbles settings"
  wizard_info "Docs: https://docs.bluebubbles.app/"
  echo

  local bb_url bb_pass
  wizard_prompt bb_url "BlueBubbles URL" "${BLUEBUBBLES_URL:-http://host.docker.internal:1234}"
  wizard_prompt_secret bb_pass "BlueBubbles server password"

  if [[ -z "$bb_pass" ]]; then
    wizard_err "BlueBubbles password is required."
    exit 1
  fi

  wizard_step 2 "Save settings"
  wizard_set_env "BLUEBUBBLES_URL" "$bb_url"
  wizard_set_env "BLUEBUBBLES_PASSWORD" "$bb_pass"
  export BLUEBUBBLES_URL="$bb_url"
  export BLUEBUBBLES_PASSWORD="$bb_pass"
  wizard_ok "Saved to .env"

  wizard_finish_bridge imessage
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_imessage
