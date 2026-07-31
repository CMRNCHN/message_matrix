#!/usr/bin/env bash
set -euo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$W/lib/wizard-ui.sh"
# shellcheck disable=SC1091
source "$W/lib/bridges.sh"
# shellcheck disable=SC1091
source "$W/wizards/_common.sh"

wizard_telegram() {
  wizard_require_env
  wizard_require_docker
  wizard_header "Telegram" "Puppet your Telegram account into Matrix"

  wizard_step 1 "Get Telegram API credentials"
  wizard_info "Visit https://my.telegram.org/apps and create an application"
  wizard_info "You need api_id (number) and api_hash (string)"
  echo

  local api_id api_hash
  wizard_prompt api_id "Telegram api_id" "${TELEGRAM_API_ID:-}"
  wizard_prompt api_hash "Telegram api_hash" "${TELEGRAM_API_HASH:-}"

  if [[ -z "$api_id" || -z "$api_hash" ]]; then
    wizard_err "api_id and api_hash are required."
    exit 1
  fi

  wizard_step 2 "Save credentials"
  wizard_set_env "TELEGRAM_API_ID" "$api_id"
  wizard_set_env "TELEGRAM_API_HASH" "$api_hash"
  wizard_ok "Saved to .env"
  export TELEGRAM_API_ID="$api_id"
  export TELEGRAM_API_HASH="$api_hash"

  wizard_finish_bridge telegram
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && wizard_telegram
