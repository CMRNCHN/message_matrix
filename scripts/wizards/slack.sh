#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_slack() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Slack" "Bridge Slack workspaces into Matrix"

  wizard_step 1 "Prerequisites"
  wizard_info "Slack workspace access"
  wizard_info "Login via OAuth or token in the bridge bot chat after setup"
  wizard_info "Docs: https://docs.mau.fi/bridges/go/slack/"
  wizard_press_enter

  wizard_step 2 "Confirm"
  if ! wizard_confirm "Set up Slack bridge now?"; then
    wizard_warn "Cancelled."
    exit 0
  fi

  wizard_finish_bridge slack
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_slack
