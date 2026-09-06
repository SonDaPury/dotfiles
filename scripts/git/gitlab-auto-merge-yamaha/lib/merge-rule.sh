#!/usr/bin/env bash

RULE_SOURCE=""
RULE_TARGET=""

rule_parse() {
  local rule="$1"
  [[ "$rule" == *:* ]] || return 1

  RULE_SOURCE="${rule%%:*}"
  RULE_TARGET="${rule#*:}"
  [[ -n "$RULE_SOURCE" && -n "$RULE_TARGET" && "$RULE_TARGET" != *:* ]] || return 1
  [[ "$RULE_SOURCE" != *$'\n'* && "$RULE_TARGET" != *$'\n'* ]] || return 1
}

rule_collect_unique_branches() {
  local rule
  for rule in "$@"; do
    rule_parse "$rule" || return 1
    printf '%s\n%s\n' "$RULE_SOURCE" "$RULE_TARGET"
  done | LC_ALL=C sort -u
}
