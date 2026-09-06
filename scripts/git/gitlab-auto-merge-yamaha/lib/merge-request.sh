#!/usr/bin/env bash

# Business rules for one source:target merge path. API transport is isolated in
# gitlab-api.sh; this module decides which action is appropriate.
MR_MERGED_COUNT=0
MR_OPEN_COUNT=0
MR_CONFLICT_COUNT=0
MR_NO_CHANGE_COUNT=0
MR_TIMEOUT_COUNT=0
MR_FAILED_COUNT=0
MR_DRY_RUN_COUNT=0
MR_HAS_FAILURE=false
MR_EXIT_CODE=0
MR_SUMMARY_ROWS=()

MR_STATUS=""
MR_DETAIL_STATUS=""
MR_MERGE_STATE=""
MR_URL=""
MR_REASON=""

merge_request_init() {
  MR_MERGED_COUNT=0
  MR_OPEN_COUNT=0
  MR_CONFLICT_COUNT=0
  MR_NO_CHANGE_COUNT=0
  MR_TIMEOUT_COUNT=0
  MR_FAILED_COUNT=0
  MR_DRY_RUN_COUNT=0
  MR_HAS_FAILURE=false
  MR_EXIT_CODE=0
  MR_SUMMARY_ROWS=()
}

merge_request_set_exit_code() {
  local code="$1"
  if ((code > MR_EXIT_CODE)); then
    MR_EXIT_CODE="$code"
  fi
}

merge_request_log_result() {
  local source_branch="$1"
  local target_branch="$2"
  logger_info "┌─ Rule: $source_branch → $target_branch"
  logger_info "│  MR URL: ${MR_URL:-N/A}"
  logger_info "│  Result: $MR_STATUS"
  logger_info "│  Reason: $MR_REASON"
  logger_info "└────────────────────────────────────────────"
  MR_SUMMARY_ROWS+=("$source_branch -> $target_branch | $MR_STATUS | ${MR_URL:-N/A} | $MR_REASON")
}

merge_request_detailed_status() {
  local mr_json="$1"
  local detailed merge_status has_conflicts
  detailed="$(jq -r '.detailed_merge_status // empty' <<<"$mr_json")"
  merge_status="$(jq -r '.merge_status // empty' <<<"$mr_json")"
  has_conflicts="$(jq -r '.has_conflicts // false' <<<"$mr_json")"

  MR_DETAIL_STATUS="${detailed:-$merge_status}"
  if [[ "$has_conflicts" == true || "$MR_DETAIL_STATUS" == conflict ]]; then
    MR_MERGE_STATE=conflict
    return
  fi

  case "$MR_DETAIL_STATUS" in
    mergeable|can_be_merged) MR_MERGE_STATE=mergeable ;;
    checking|unchecked|approvals_syncing|preparing|cannot_be_merged_recheck) MR_MERGE_STATE=pending ;;
    *) MR_MERGE_STATE=blocked ;;
  esac
}

# On success, GITLAB_API_BODY holds the latest MR JSON and MR_DETAIL_STATUS
# identifies the terminal GitLab merge state. Returns 2 for a retry timeout.
merge_request_wait_for_status() {
  local iid="$1"
  local attempt=0 state

  while :; do
    gitlab_api_get_merge_request "$iid" || return 1
    merge_request_detailed_status "$GITLAB_API_BODY"
    state="$MR_MERGE_STATE"
    case "$state" in
      mergeable|conflict|blocked) return 0 ;;
      pending)
        if ((attempt >= RETRY_COUNT)); then
          return 2
        fi
        ((attempt += 1))
        logger_debug "MR !$iid is $MR_DETAIL_STATUS; retry $attempt/$RETRY_COUNT in ${RETRY_INTERVAL}s"
        sleep "$RETRY_INTERVAL"
        ;;
    esac
  done
}

# Sets MR_REASON to a no-change result and returns success only when both values
# are genuinely zero. This uses /changes because some GitLab self-hosted
# versions return a null changes_count in the ordinary MR details endpoint.
# Zero changes with commits remains mergeable.
merge_request_is_empty() {
  local iid="$1"
  local changes_count commits_count
  gitlab_api_get_merge_request_changes "$iid" || return 2
  changes_count="$(jq '.changes | length' <<<"$GITLAB_API_BODY")"
  [[ "$changes_count" == 0 ]] || return 1

  gitlab_api_get_merge_request_commits "$iid" || return 2
  commits_count="$(jq 'length' <<<"$GITLAB_API_BODY")"
  [[ "$commits_count" == 0 ]] || return 1

  MR_REASON="No change to merge (0 changes and 0 commits)"
  return 0
}

merge_request_close() {
  local iid="$1"
  gitlab_api_close_merge_request "$iid"
}

merge_request_process_rule() {
  local rule="$1"
  local source_branch target_branch mr_json iid existing=false wait_result state empty_result
  rule_parse "$rule" || utils_die "Invalid merge rule: $rule"
  source_branch="$RULE_SOURCE"
  target_branch="$RULE_TARGET"
  MR_STATUS=""
  MR_URL=""
  MR_REASON=""
  MR_DETAIL_STATUS=""
  MR_MERGE_STATE=""

  if [[ "$DRY_RUN" == true ]]; then
    MR_STATUS=DRY_RUN
    MR_REASON="Would find or create MR, then evaluate merge status"
    ((MR_DRY_RUN_COUNT += 1))
    merge_request_log_result "$source_branch" "$target_branch"
    return 0
  fi

  if ! gitlab_api_get_open_merge_request "$source_branch" "$target_branch"; then
    MR_STATUS=FAILED
    MR_REASON="Unable to find an existing open MR"
    ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
    merge_request_set_exit_code 4
    merge_request_log_result "$source_branch" "$target_branch"
    return 1
  fi

  mr_json="$GITLAB_API_BODY"
  if [[ "$mr_json" == null ]]; then
    local title="Merge $source_branch into $target_branch"
    if ! gitlab_api_create_merge_request "$source_branch" "$target_branch" "$title"; then
      MR_STATUS=FAILED
      MR_REASON="Unable to create MR"
      ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
      merge_request_set_exit_code 4
      merge_request_log_result "$source_branch" "$target_branch"
      return 1
    fi
    mr_json="$GITLAB_API_BODY"
    MR_REASON="New MR created"
  else
    existing=true
    MR_REASON="Using existing open MR"
  fi

  iid="$(jq -r '.iid // empty' <<<"$mr_json")"
  MR_URL="$(jq -r '.web_url // empty' <<<"$mr_json")"
  if [[ ! "$iid" =~ ^[0-9]+$ ]]; then
    MR_STATUS=FAILED
    MR_REASON="GitLab returned an MR without a valid IID"
    ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
    merge_request_set_exit_code 4
    merge_request_log_result "$source_branch" "$target_branch"
    return 1
  fi

  if merge_request_wait_for_status "$iid"; then
    :
  else
    wait_result=$?
    if [[ "$wait_result" == 2 ]]; then
      MR_STATUS=CHECKING_TIMEOUT
      MR_REASON="Merge status stayed $MR_DETAIL_STATUS after $RETRY_COUNT retries"
      ((MR_TIMEOUT_COUNT += 1)); MR_HAS_FAILURE=true
      merge_request_set_exit_code 3
    else
      MR_STATUS=FAILED
      MR_REASON="Unable to refresh merge status"
      ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
      merge_request_set_exit_code 4
    fi
    merge_request_log_result "$source_branch" "$target_branch"
    return 1
  fi

  MR_URL="$(jq -r '.web_url // empty' <<<"$GITLAB_API_BODY")"
  merge_request_detailed_status "$GITLAB_API_BODY"
  state="$MR_MERGE_STATE"

  # GitLab can report conflict for an already-aligned branch pair. A truly
  # empty MR is a no-change result, so it must take priority over that status.
  if merge_request_is_empty "$iid"; then
    if merge_request_close "$iid"; then
      MR_STATUS=NO_CHANGE_TO_MERGE
      MR_REASON="$MR_REASON; MR closed"
      ((MR_NO_CHANGE_COUNT += 1))
      merge_request_log_result "$source_branch" "$target_branch"
      return 0
    fi
    MR_STATUS=FAILED
    MR_REASON="No change to merge (0 changes and 0 commits), but GitLab could not close the MR"
    ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
    merge_request_set_exit_code 4
    merge_request_log_result "$source_branch" "$target_branch"
    return 1
  else
    empty_result=$?
    if [[ "$empty_result" == 2 ]]; then
      MR_STATUS=FAILED
      MR_REASON="Unable to inspect MR changes or commits"
      ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
      merge_request_set_exit_code 4
      merge_request_log_result "$source_branch" "$target_branch"
      return 1
    fi
  fi

  if [[ "$state" == conflict ]]; then
    if merge_request_close "$iid"; then
      MR_STATUS=CONFLICT_CLOSED
      MR_REASON="Conflict detected (merge status: $MR_DETAIL_STATUS); MR closed"
      ((MR_CONFLICT_COUNT += 1)); MR_HAS_FAILURE=true
      merge_request_set_exit_code 2
      merge_request_log_result "$source_branch" "$target_branch"
      return 1
    fi
    MR_STATUS=FAILED
    MR_REASON="Conflict detected, but GitLab could not close the MR"
    ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
    merge_request_set_exit_code 4
    merge_request_log_result "$source_branch" "$target_branch"
    return 1
  fi

  if [[ "$state" != mergeable ]]; then
    MR_STATUS=OPEN_BLOCKED
    MR_REASON="MR is not conflicted but cannot be merged yet (merge status: $MR_DETAIL_STATUS)"
    ((MR_OPEN_COUNT += 1)); MR_HAS_FAILURE=true
    merge_request_set_exit_code 2
    merge_request_log_result "$source_branch" "$target_branch"
    return 1
  fi

  if [[ "$AUTO_MERGE" == false ]]; then
    MR_STATUS=OPEN
    if [[ "$existing" == true ]]; then
      MR_REASON="Existing MR is mergeable; AUTO_MERGE=false"
    else
      MR_REASON="New MR is mergeable; AUTO_MERGE=false"
    fi
    ((MR_OPEN_COUNT += 1))
    merge_request_log_result "$source_branch" "$target_branch"
    return 0
  fi

  if gitlab_api_merge_merge_request "$iid"; then
    MR_STATUS=MERGED
    MR_REASON="MR merged (merge status: $MR_DETAIL_STATUS)"
    ((MR_MERGED_COUNT += 1))
    merge_request_log_result "$source_branch" "$target_branch"
    return 0
  fi

  MR_STATUS=FAILED
  MR_REASON="GitLab could not merge an MR reported as mergeable"
  ((MR_FAILED_COUNT += 1)); MR_HAS_FAILURE=true
  merge_request_set_exit_code 4
  merge_request_log_result "$source_branch" "$target_branch"
  return 1
}

merge_request_print_summary() {
  logger_summary "Merged: $MR_MERGED_COUNT | Open: $MR_OPEN_COUNT | No change: $MR_NO_CHANGE_COUNT | Conflict closed: $MR_CONFLICT_COUNT | Timeout: $MR_TIMEOUT_COUNT | Failed: $MR_FAILED_COUNT | Dry run: $MR_DRY_RUN_COUNT"
  local row
  for row in "${MR_SUMMARY_ROWS[@]}"; do
    logger_write SUMMARY "$row"
  done
}
