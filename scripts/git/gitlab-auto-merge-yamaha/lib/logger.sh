#!/usr/bin/env bash

LOGGER_FILE=""

logger_color_enabled() {
  [[ "${NO_COLOR:-}" == "" ]] || return 1
  case "${COLOR_OUTPUT:-auto}" in
    true) return 0 ;;
    false) return 1 ;;
    auto) [[ -t 1 ]] ;;
  esac
}

logger_icon() {
  case "$1" in
    INFO) printf 'ℹ' ;;
    WARN) printf '⚠' ;;
    ERROR) printf '✖' ;;
    SUCCESS) printf '✔' ;;
    DEBUG) printf '•' ;;
    SUMMARY) printf '📊' ;;
    *) printf '•' ;;
  esac
}

logger_color() {
  case "$1" in
    INFO) printf '36' ;;
    WARN) printf '33' ;;
    ERROR) printf '31' ;;
    SUCCESS) printf '32' ;;
    DEBUG) printf '90' ;;
    SUMMARY) printf '35' ;;
    *) printf '0' ;;
  esac
}

logger_init() {
  LOGGER_FILE="$1"
  mkdir -p -- "$(dirname -- "$LOGGER_FILE")"
  : > "$LOGGER_FILE"
}

logger_write() {
  local level="$1"
  shift
  local message="$*"
  local icon color line
  icon="$(logger_icon "$level")"
  color="$(logger_color "$level")"
  line="$(date '+%Y-%m-%d %H:%M:%S') [$icon $level] $message"

  # Keep the saved log portable: color escape codes go to the terminal only.
  printf '%s\n' "$line" >> "$LOGGER_FILE"
  if logger_color_enabled; then
    printf '\033[%sm%s\033[0m\n' "$color" "$line"
  else
    printf '%s\n' "$line"
  fi
}

logger_info() { logger_write INFO "$*"; }
logger_warn() { logger_write WARN "$*"; }
logger_error() { logger_write ERROR "$*" >&2; }
logger_success() { logger_write SUCCESS "$*"; }

logger_debug() {
  [[ "${VERBOSE:-false}" == true ]] && logger_write DEBUG "$*"
}

logger_summary() {
  logger_write SUMMARY "━━━━━━━━━━━━━━━━━━ SUMMARY ━━━━━━━━━━━━━━━━━━"
  logger_write SUMMARY "$*"
  logger_write SUMMARY "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
