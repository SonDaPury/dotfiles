#!/usr/bin/env bash
# Synchronize every branch named in MERGE_RULES. GitLab API operations live in
# lib/gitlab-api.sh and will be connected to rule processing in the next phase.
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_BRANCH=""

# shellcheck source=lib/utils.sh
source "$SCRIPT_DIR/lib/utils.sh"
# shellcheck source=lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=lib/logger.sh
source "$SCRIPT_DIR/lib/logger.sh"
# shellcheck source=lib/merge-rule.sh
source "$SCRIPT_DIR/lib/merge-rule.sh"
# shellcheck source=lib/git.sh
source "$SCRIPT_DIR/lib/git.sh"
# shellcheck source=lib/gitlab-api.sh
source "$SCRIPT_DIR/lib/gitlab-api.sh"
# shellcheck source=lib/merge-request.sh
source "$SCRIPT_DIR/lib/merge-request.sh"

usage() {
  cat <<'EOF'
Usage: ./merge-sync.sh --config <path> [--dry-run] [--verbose]

Synchronizes all unique branches in MERGE_RULES, then creates or processes a
GitLab Merge Request for every source:target rule.

Options:
  -c, --config PATH  Bash configuration file (required)
      --dry-run      Show the branches that would be synchronized
  -v, --verbose      Print debug messages
  -h, --help         Show this help
EOF
}

main() {
  local config_path=""
  local dry_run_override=""
  local verbose_override=""

  while (($#)); do
    case "$1" in
      -c|--config)
        (($# >= 2)) || utils_die "Missing value for $1"
        config_path="$2"
        shift 2
        ;;
      --dry-run) dry_run_override=true; shift ;;
      -v|--verbose) verbose_override=true; shift ;;
      -h|--help) usage; return 0 ;;
      *) utils_die "Unknown option: $1 (use --help)" ;;
    esac
  done

  [[ -n "$config_path" ]] || { usage >&2; utils_die "--config is required"; }
  config_load "$config_path"
  [[ -z "$dry_run_override" ]] || DRY_RUN="$dry_run_override"
  [[ -z "$verbose_override" ]] || VERBOSE="$verbose_override"
  config_validate

  logger_init "$LOG_FILE"
  logger_info "Starting branch synchronization"
  logger_info "Project ID: $PROJECT_ID"
  logger_info "Local repository: $LOCAL_REPO_PATH"

  if [[ "$DRY_RUN" == true ]]; then
    logger_warn "Dry run enabled; no Git commands will modify the repository"
  else
    logger_info "Checking GitLab project access"
    if ! gitlab_api_get_project; then
      logger_error "GitLab project preflight failed; no local branch or MR was changed"
      return 4
    fi
    logger_success "GitLab project verified: $(jq -r '.path_with_namespace // .name // "unknown"' <<<"$GITLAB_API_BODY")"
  fi

  cd -- "$LOCAL_REPO_PATH"
  git_require_repo
  git_require_clean_worktree

  ORIGINAL_BRANCH="$(git_current_branch)"
  trap 'git_restore_branch "$ORIGINAL_BRANCH" || true' EXIT

  git_fetch_origin

  local -a branches=()
  mapfile -t branches < <(rule_collect_unique_branches "${MERGE_RULES[@]}")
  local branch
  for branch in "${branches[@]}"; do
    logger_info "Synchronizing branch: $branch"
    git_sync_branch "$branch"
    logger_success "Synchronized: $branch"
  done

  merge_request_init
  local rule
  for rule in "${MERGE_RULES[@]}"; do
    merge_request_process_rule "$rule" || true
  done

  logger_summary "Synchronized branches: ${#branches[@]}"
  merge_request_print_summary
  if [[ "$MR_HAS_FAILURE" == true ]]; then
    logger_error "One or more merge rules need attention"
    return "$MR_EXIT_CODE"
  fi
  logger_success "Merge workflow complete"
}

main "$@"
