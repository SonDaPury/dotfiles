#!/usr/bin/env bash

utils_die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

utils_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

utils_require_command() {
  utils_command_exists "$1" || utils_die "Required command not found: $1"
}

utils_is_boolean() {
  [[ "$1" == true || "$1" == false ]]
}

utils_resolve_path() {
  local path="$1"
  local base_dir="$2"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$base_dir" "$path"
  fi
}
