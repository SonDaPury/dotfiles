#!/usr/bin/env bash

# GitLab REST API client. Business rules intentionally live elsewhere; every
# public function here performs one API operation and leaves the decoded JSON
# response in GITLAB_API_BODY.
GITLAB_API_BODY=""
GITLAB_API_STATUS=""

gitlab_api_url() {
  local endpoint="$1"
  printf '%s/api/v4%s\n' "${GITLAB_URL%/}" "$endpoint"
}

gitlab_api_url_encode() {
  printf '%s' "$1" | jq -sRr '@uri'
}

gitlab_api_error_message() {
  jq -r 'if type == "object" then (.message // .error // .error_description // "Unknown GitLab API error") else "Unknown GitLab API error" end' \
    <<<"$GITLAB_API_BODY" 2>/dev/null || printf '%s' 'Unknown GitLab API error'
}

gitlab_api_request() {
  local method="$1"
  local endpoint="$2"
  local payload="${3:-}"
  local response
  local -a curl_args=(
    --silent
    --show-error
    --request "$method"
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN"
    --header 'Accept: application/json'
    --connect-timeout "$GITLAB_API_CONNECT_TIMEOUT"
    --max-time "$GITLAB_API_TIMEOUT"
    --write-out $'\n%{http_code}'
  )

  if [[ -n "$payload" ]]; then
    curl_args+=(--header 'Content-Type: application/json' --data "$payload")
  fi

  if ! response="$(curl "${curl_args[@]}" "$(gitlab_api_url "$endpoint")")"; then
    logger_error "GitLab API request failed: $method $endpoint"
    return 1
  fi

  GITLAB_API_STATUS="${response##*$'\n'}"
  GITLAB_API_BODY="${response%$'\n'*}"
  [[ "$GITLAB_API_STATUS" =~ ^[0-9]{3}$ ]] || {
    logger_error "GitLab API returned an invalid HTTP status for: $method $endpoint"
    return 1
  }
}

gitlab_api_expect_status() {
  local expected
  for expected in "$@"; do
    [[ "$GITLAB_API_STATUS" == "$expected" ]] && return 0
  done

  logger_error "GitLab API HTTP $GITLAB_API_STATUS: $(gitlab_api_error_message)"
  return 1
}

gitlab_api_get_project() {
  gitlab_api_request GET "/projects/$PROJECT_ID" || return
  gitlab_api_expect_status 200
}

# Returns a single MR object, or JSON null when no opened MR matches the rule.
gitlab_api_get_open_merge_request() {
  local source_branch="$1"
  local target_branch="$2"
  local source_encoded target_encoded
  source_encoded="$(gitlab_api_url_encode "$source_branch")"
  target_encoded="$(gitlab_api_url_encode "$target_branch")"

  gitlab_api_request GET "/projects/$PROJECT_ID/merge_requests?state=opened&source_branch=$source_encoded&target_branch=$target_encoded&order_by=updated_at&sort=desc&per_page=1" || return
  gitlab_api_expect_status 200 || return
  GITLAB_API_BODY="$(jq -c '.[0] // null' <<<"$GITLAB_API_BODY")"
}

gitlab_api_create_merge_request() {
  local source_branch="$1"
  local target_branch="$2"
  local title="$3"
  local remove_source=false
  [[ "$DELETE_SOURCE_BRANCH" == true ]] && remove_source=true
  local payload
  payload="$(jq -cn \
    --arg source_branch "$source_branch" \
    --arg target_branch "$target_branch" \
    --arg title "$title" \
    --argjson remove_source_branch "$remove_source" \
    '{source_branch: $source_branch, target_branch: $target_branch, title: $title, remove_source_branch: $remove_source_branch}')"

  gitlab_api_request POST "/projects/$PROJECT_ID/merge_requests" "$payload" || return
  gitlab_api_expect_status 201
}

gitlab_api_get_merge_request() {
  local iid="$1"
  [[ "$iid" =~ ^[0-9]+$ ]] || utils_die "Merge request IID must be numeric"
  gitlab_api_request GET "/projects/$PROJECT_ID/merge_requests/$iid" || return
  gitlab_api_expect_status 200
}

gitlab_api_get_merge_request_commits() {
  local iid="$1"
  [[ "$iid" =~ ^[0-9]+$ ]] || utils_die "Merge request IID must be numeric"
  gitlab_api_request GET "/projects/$PROJECT_ID/merge_requests/$iid/commits?per_page=100" || return
  gitlab_api_expect_status 200
}

gitlab_api_get_merge_request_changes() {
  local iid="$1"
  [[ "$iid" =~ ^[0-9]+$ ]] || utils_die "Merge request IID must be numeric"
  gitlab_api_request GET "/projects/$PROJECT_ID/merge_requests/$iid/changes" || return
  gitlab_api_expect_status 200
}

gitlab_api_merge_merge_request() {
  local iid="$1"
  [[ "$iid" =~ ^[0-9]+$ ]] || utils_die "Merge request IID must be numeric"
  local remove_source=false
  [[ "$DELETE_SOURCE_BRANCH" == true ]] && remove_source=true
  local payload
  payload="$(jq -cn --argjson should_remove_source_branch "$remove_source" '{should_remove_source_branch: $should_remove_source_branch}')"

  gitlab_api_request PUT "/projects/$PROJECT_ID/merge_requests/$iid/merge" "$payload" || return
  gitlab_api_expect_status 200
}

gitlab_api_close_merge_request() {
  local iid="$1"
  [[ "$iid" =~ ^[0-9]+$ ]] || utils_die "Merge request IID must be numeric"
  gitlab_api_request PUT "/projects/$PROJECT_ID/merge_requests/$iid" '{"state_event":"close"}' || return
  gitlab_api_expect_status 200
}

gitlab_api_delete_branch() {
  local branch="$1"
  local branch_encoded
  branch_encoded="$(gitlab_api_url_encode "$branch")"
  gitlab_api_request DELETE "/projects/$PROJECT_ID/repository/branches/$branch_encoded" || return
  gitlab_api_expect_status 200 204
}
