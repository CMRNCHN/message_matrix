#!/usr/bin/env bash
# Interactive wizard UI helpers for Message Matrix connection setup.

WIZARD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -t 1 ]]; then
  WIZ_BOLD=$'\033[1m'
  WIZ_DIM=$'\033[2m'
  WIZ_GREEN=$'\033[32m'
  WIZ_YELLOW=$'\033[33m'
  WIZ_BLUE=$'\033[34m'
  WIZ_CYAN=$'\033[36m'
  WIZ_RED=$'\033[31m'
  WIZ_RESET=$'\033[0m'
else
  WIZ_BOLD= WIZ_DIM= WIZ_GREEN= WIZ_YELLOW= WIZ_BLUE= WIZ_CYAN= WIZ_RED= WIZ_RESET=
fi

wizard_header() {
  local title="$1"
  local subtitle="${2:-Connect a messaging platform to your Matrix inbox}"
  echo
  echo "${WIZ_CYAN}╔══════════════════════════════════════════════════════════════╗${WIZ_RESET}"
  printf "${WIZ_CYAN}║${WIZ_RESET} %-60s ${WIZ_CYAN}║${WIZ_RESET}\n" "${WIZ_BOLD}${title}${WIZ_RESET}"
  printf "${WIZ_CYAN}║${WIZ_RESET} ${WIZ_DIM}%-60s${WIZ_RESET} ${WIZ_CYAN}║${WIZ_RESET}\n" "$subtitle"
  echo "${WIZ_CYAN}╚══════════════════════════════════════════════════════════════╝${WIZ_RESET}"
  echo
}

wizard_step() {
  local num="$1"
  local title="$2"
  echo "${WIZ_BLUE}Step ${num}${WIZ_RESET} ${WIZ_BOLD}${title}${WIZ_RESET}"
  echo "${WIZ_DIM}$(printf '%.0s─' {1..64})${WIZ_RESET}"
}

wizard_info() {
  echo "  ${WIZ_DIM}→${WIZ_RESET} $*"
}

wizard_ok() {
  echo "  ${WIZ_GREEN}✓${WIZ_RESET} $*"
}

wizard_warn() {
  echo "  ${WIZ_YELLOW}!${WIZ_RESET} $*"
}

wizard_err() {
  echo "  ${WIZ_RED}✗${WIZ_RESET} $*" >&2
}

wizard_prompt() {
  local var_name="$1"
  local prompt="$2"
  local default="${3:-}"
  local value=""
  if [[ -n "$default" ]]; then
    read -r -p "  ${prompt} [${default}]: " value
    value="${value:-$default}"
  else
    read -r -p "  ${prompt}: " value
  fi
  printf -v "$var_name" '%s' "$value"
}

wizard_prompt_secret() {
  local var_name="$1"
  local prompt="$2"
  local value=""
  read -r -s -p "  ${prompt}: " value
  echo
  printf -v "$var_name" '%s' "$value"
}

wizard_confirm() {
  local prompt="$1"
  local default="${2:-y}"
  local hint="Y/n"
  [[ "$default" == "n" ]] && hint="y/N"
  local answer=""
  read -r -p "  ${prompt} [${hint}]: " answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy] ]]
}

wizard_press_enter() {
  read -r -p "  Press Enter to continue..."
}

wizard_require_env() {
  if [[ ! -f "$WIZARD_ROOT/.env" ]]; then
    wizard_err "Missing .env — run: cp .env.example .env && ./scripts/bootstrap.sh"
    exit 1
  fi
  set -a
  # shellcheck disable=SC1091
  source "$WIZARD_ROOT/.env"
  set +a
}

wizard_require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    wizard_err "Docker is required but not installed."
    exit 1
  fi
}

wizard_set_env() {
  local key="$1"
  local value="$2"
  local env_file="$WIZARD_ROOT/.env"
  if grep -q "^${key}=" "$env_file" 2>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^${key}=.*|${key}=${value}|" "$env_file"
    else
      sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
    fi
  else
    echo "${key}=${value}" >> "$env_file"
  fi
}

wizard_status_icon() {
  local status="$1"
  case "$status" in
    running)    echo "${WIZ_GREEN}● running${WIZ_RESET}" ;;
    configured) echo "${WIZ_YELLOW}● configured${WIZ_RESET}" ;;
    experimental) echo "${WIZ_YELLOW}◌ experimental${WIZ_RESET}" ;;
    *)          echo "${WIZ_DIM}○ not set up${WIZ_RESET}" ;;
  esac
}
