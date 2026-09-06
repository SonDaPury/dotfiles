#!/usr/bin/env bash

CONFIG_PATH=""
CONFIG_DIR=""

config_load_gitlab_token() {
  local env_path="$1"
  local line=""
  local value=""

  [[ -f "$env_path" ]] || utils_die "GitLab secret file not found: $env_path"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == GITLAB_TOKEN=* ]] || continue
    value="${line#GITLAB_TOKEN=}"
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi
    [[ -n "$value" ]] || utils_die "GITLAB_TOKEN is empty in $env_path"
    GITLAB_TOKEN="$value"
    return 0
  done < "$env_path"
  utils_die "GITLAB_TOKEN is missing from $env_path"
}

config_load() {
  local requested_path="$1"
  [[ -f "$requested_path" ]] || utils_die "Configuration file not found: $requested_path"

  CONFIG_PATH="$(cd -- "$(dirname -- "$requested_path")" && pwd)/$(basename -- "$requested_path")"
  CONFIG_DIR="$(dirname -- "$CONFIG_PATH")"

  # Configuration is deliberately Bash so MERGE_RULES can be an array. Only
  # load configuration files you trust.
  # shellcheck disable=SC1090
  source "$CONFIG_PATH"

  # Prefer an already-exported token. Otherwise load only GITLAB_TOKEN from
  # the local secret file; never source arbitrary env-file contents.
  if [[ -z "${GITLAB_TOKEN:-}" ]]; then
    [[ -n "${GITLAB_ENV_FILE:-}" ]] || utils_die "Missing required config value: GITLAB_ENV_FILE"
    config_load_gitlab_token "$GITLAB_ENV_FILE"
  fi

  # Keep these optional for existing project config files.
  GITLAB_API_TIMEOUT="${GITLAB_API_TIMEOUT:-30}"
  GITLAB_API_CONNECT_TIMEOUT="${GITLAB_API_CONNECT_TIMEOUT:-10}"
  COLOR_OUTPUT="${COLOR_OUTPUT:-auto}"
}

config_validate() {
  local name
  for name in LOCAL_REPO_PATH GITLAB_URL PROJECT_ID GITLAB_TOKEN LOG_FILE RETRY_COUNT RETRY_INTERVAL GITLAB_API_TIMEOUT GITLAB_API_CONNECT_TIMEOUT; do
    [[ -n "${!name:-}" ]] || utils_die "Missing required config value: $name"
  done

  [[ "$GITLAB_URL" =~ ^https?:// ]] || utils_die "GITLAB_URL must start with http:// or https://"
  [[ "$PROJECT_ID" =~ ^[0-9]+$ ]] || utils_die "PROJECT_ID must be numeric"
  [[ "$RETRY_COUNT" =~ ^[0-9]+$ ]] || utils_die "RETRY_COUNT must be a non-negative integer"
  [[ "$RETRY_INTERVAL" =~ ^[0-9]+$ ]] || utils_die "RETRY_INTERVAL must be a non-negative integer"
  [[ "$GITLAB_API_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || utils_die "GITLAB_API_TIMEOUT must be a positive integer"
  [[ "$GITLAB_API_CONNECT_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || utils_die "GITLAB_API_CONNECT_TIMEOUT must be a positive integer"

  for name in AUTO_MERGE DELETE_SOURCE_BRANCH DRY_RUN VERBOSE; do
    utils_is_boolean "${!name:-}" || utils_die "$name must be true or false"
  done
  [[ "$COLOR_OUTPUT" == auto || "$COLOR_OUTPUT" == true || "$COLOR_OUTPUT" == false ]] || utils_die "COLOR_OUTPUT must be auto, true, or false"

  declare -p MERGE_RULES >/dev/null 2>&1 || utils_die "MERGE_RULES must be a Bash array"
  ((${#MERGE_RULES[@]} > 0)) || utils_die "MERGE_RULES cannot be empty"

  local rule
  for rule in "${MERGE_RULES[@]}"; do
    rule_parse "$rule" >/dev/null || utils_die "Invalid MERGE_RULES entry: $rule"
  done

  LOCAL_REPO_PATH="$(utils_resolve_path "$LOCAL_REPO_PATH" "$CONFIG_DIR")"
  [[ -d "$LOCAL_REPO_PATH" ]] || utils_die "LOCAL_REPO_PATH is not a directory: $LOCAL_REPO_PATH"

  LOG_FILE="$(utils_resolve_path "$LOG_FILE" "$CONFIG_DIR")"
  utils_require_command git
  utils_require_command curl
  utils_require_command jq
}
