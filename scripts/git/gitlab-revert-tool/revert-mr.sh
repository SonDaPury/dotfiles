#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

VERSION="1.1.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
STATE_ROOT="${STATE_ROOT:-$ROOT_DIR/.revert-state}"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

cleanup() {
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    warn "Operation failed (exit $rc). Review state under: $STATE_ROOT"
  fi
}
trap cleanup EXIT

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }

load_env() {
  [[ -f "$ENV_FILE" ]] || die "Missing $ENV_FILE. Copy .env.example to .env and configure it."
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

api() {
  local method="$1" path="$2" data="${3:-}"
  local args=(--silent --show-error --fail-with-body --request "$method" \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --header 'Content-Type: application/json')
  [[ -n "$data" ]] && args+=(--data "$data")
  curl "${args[@]}" "${GITLAB_URL%/}/api/v4${path}"
}

urlencode() { jq -rn --arg v "$1" '$v|@uri'; }

json_get() { jq -er "$1" 2>/dev/null; }
json_get_opt() { jq -r "$1 // empty" 2>/dev/null; }

ensure_reverted_label() {
  local label="Reverted" encoded payload
  encoded="$(urlencode "$label")"

  # Project labels are scoped to the current GitLab project. If the label already
  # exists, GET succeeds. Otherwise create it. A 409/race is harmless because
  # the subsequent MR update only needs the label to exist.
  if api GET "/projects/${PROJECT_ID}/labels/${encoded}" >/dev/null 2>&1; then
    return 0
  fi

  payload="$(jq -n --arg name "$label" '{name:$name,color:"#6B7280"}')"
  if ! api POST "/projects/${PROJECT_ID}/labels" "$payload" >/dev/null 2>&1; then
    # Re-check in case another process created it between GET and POST.
    api GET "/projects/${PROJECT_ID}/labels/${encoded}" >/dev/null 2>&1 || \
      die "Cannot create or find GitLab label '$label'. MR !${MR_IID} labels were not changed."
  fi
}

replace_mr_labels_with_reverted() {
  ensure_reverted_label

  # GitLab's labels field is a comma-separated list. Sending exactly one value
  # replaces the existing label set; it does not append to it.
  local payload updated
  payload="$(jq -n --arg labels "Reverted" '{labels:$labels}')"
  updated="$(api PUT "/projects/${PROJECT_ID}/merge_requests/${MR_IID}" "$payload")" || \
    die "Revert MRs were created, but replacing labels on original MR !${MR_IID} failed. Check the MR in GitLab before retrying."

  local final_labels
  final_labels="$(jq -r '.labels // [] | join(", ")' <<<"$updated")"
  [[ "$final_labels" == "Reverted" ]] || \
    die "GitLab did not confirm the expected label state on MR !${MR_IID}. Current labels: ${final_labels:-<none>}"

  log "Original MR !${MR_IID} labels replaced with: Reverted"
  printf '%s\n' "$updated" > "$(state_dir)/original-mr-after-label-update.json"
}

confirm() {
  local prompt="$1" default="${2:-N}" answer
  read -r -p "$prompt [y/N]: " answer || true
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

normalize_flow() {
  local expected=(develop staging demo_pkg uat main)
  local actual=( $BRANCH_FLOW )
  [[ ${#actual[@]} -eq 5 ]] || die "BRANCH_FLOW must contain exactly: develop staging demo_pkg uat main"
  for i in "${!expected[@]}"; do [[ "${actual[$i]}" == "${expected[$i]}" ]] || die "BRANCH_FLOW must be exactly: develop staging demo_pkg uat main"; done
  FLOW=("${actual[@]}")
}

parse_mr_url() {
  local url="$1" encoded project_path mr_iid
  [[ "$url" =~ ^https?:// ]] || die "MR URL must start with http:// or https://"
  encoded="${url#*://}"; encoded="${encoded#*/}"; encoded="${encoded%%/-/merge_requests/*}"
  [[ "$url" =~ /-/merge_requests/([0-9]+)(/|\?|#|$) ]] || die "Cannot parse merge request IID from URL"
  mr_iid="${BASH_REMATCH[1]}"
  project_path="$encoded"
  [[ -n "$project_path" ]] || die "Cannot parse project path from MR URL"
  PROJECT_ID="$(urlencode "$project_path")"
  MR_IID="$mr_iid"
}

fetch_mr() {
  MR_JSON="$(api GET "/projects/${PROJECT_ID}/merge_requests/${MR_IID}")" || die "Cannot fetch MR !${MR_IID}. Check URL/token/project access."
  local state
  state="$(json_get_opt '.state' <<<"$MR_JSON")"
  [[ "$state" == "merged" ]] || die "MR !${MR_IID} is not merged (state=${state:-unknown})."
  MR_TITLE="$(json_get_opt '.title' <<<"$MR_JSON")"
  MR_WEB_URL="$(json_get_opt '.web_url' <<<"$MR_JSON")"
  MR_TARGET="$(json_get_opt '.target_branch' <<<"$MR_JSON")"
  MR_SOURCE="$(json_get_opt '.source_branch' <<<"$MR_JSON")"
  MR_MERGE_SHA="$(json_get_opt '.merge_commit_sha' <<<"$MR_JSON")"
  MR_SQUASH_SHA="$(json_get_opt '.squash_commit_sha' <<<"$MR_JSON")"
  [[ "$MR_TARGET" == "develop" ]] || die "MR !${MR_IID} targets '$MR_TARGET'. This tool expects the original MR to target develop."
}

fetch_project() {
  PROJECT_JSON="$(api GET "/projects/${PROJECT_ID}")" || die "Cannot fetch project metadata."
  PROJECT_ID_NUM="$(json_get '.id' <<<"$PROJECT_JSON")"
  PROJECT_NAME="$(json_get_opt '.path_with_namespace' <<<"$PROJECT_JSON")"
}

check_local_repo() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || die "Run this script from inside the Git repository."
  [[ "$(git remote get-url "$GIT_REMOTE" 2>/dev/null || true)" != "" ]] || die "Git remote '$GIT_REMOTE' not found."
  [[ -z "$(git status --porcelain)" ]] || die "Working tree is dirty. Commit/stash changes before running."
}

ensure_remote_branch() {
  local branch="$1"
  git fetch --quiet "$GIT_REMOTE" "$branch" || die "Cannot fetch branch '$branch'."
  git show-ref --verify --quiet "refs/remotes/$GIT_REMOTE/$branch" || die "Remote branch '$branch' not found."
}

get_mr_commits() {
  MR_COMMITS_JSON="$(api GET "/projects/${PROJECT_ID}/merge_requests/${MR_IID}/commits?per_page=100")" || die "Cannot fetch commits for MR !${MR_IID}."
  local n
  n="$(jq 'length' <<<"$MR_COMMITS_JSON")"
  [[ "$n" -gt 0 ]] || die "MR !${MR_IID} has no commits."
}

commit_subject() { git show -s --format=%s "$1" 2>/dev/null || true; }

find_original_commits() {
  ORIGINAL_COMMITS=()
  while IFS= read -r sha; do
    ORIGINAL_COMMITS+=("$sha")
  done < <(jq -r '.[].id' <<<"$MR_COMMITS_JSON")

  # GitLab's commits endpoint is authoritative for the MR. Verify each exists locally.
  for sha in "${ORIGINAL_COMMITS[@]}"; do
    git cat-file -e "$sha^{commit}" 2>/dev/null || git fetch --quiet "$GIT_REMOTE" "$sha" 2>/dev/null || true
  done
}

patch_id_for_commit() {
  git show --pretty=format: --no-ext-diff "$1" 2>/dev/null | git patch-id --stable 2>/dev/null | awk '{print $1}'
}

find_equivalent_on_branch() {
  local branch="$1" original="$2" patch subject candidates sha pid
  patch="$(patch_id_for_commit "$original")"
  subject="$(commit_subject "$original")"
  [[ -n "$patch" ]] || return 1

  # First use Git's patch-id over commits reachable from the branch. This handles cherry-picks with new SHAs.
  local matches=()
  while IFS= read -r sha; do
    [[ -z "$sha" ]] && continue
    pid="$(patch_id_for_commit "$sha")"
    if [[ -n "$pid" && "$pid" == "$patch" ]]; then
      matches+=("$sha")
    fi
  done < <(git rev-list "$GIT_REMOTE/$branch" --no-merges)
  if [[ ${#matches[@]} -eq 1 ]]; then
    printf '%s\n' "${matches[0]}"
    return 0
  elif [[ ${#matches[@]} -gt 1 ]]; then
    return 1
  fi

  # Fallback: GitLab cherry-pick messages often retain the original SHA.
  candidates="$(git log "$GIT_REMOTE/$branch" --format='%H%x09%s' --grep="$original" -F || true)"
  if [[ -n "$candidates" ]]; then
    sha="$(head -n1 <<<"$candidates" | cut -f1)"
    [[ -n "$sha" ]] && { printf '%s\n' "$sha"; return 0; }
  fi

  candidates="$(git log "$GIT_REMOTE/$branch" --format='%H%x09%s' --fixed-strings --grep="$subject" || true)"
  if [[ -n "$candidates" ]]; then
    local count
    count="$(wc -l <<<"$candidates" | tr -d ' ' )"
    if [[ "$count" == "1" ]]; then
      printf '%s\n' "$(cut -f1 <<<"$candidates")"
      return 0
    fi
  fi
  return 1
}

build_plan() {
  PLAN_JSON='[]'
  local target_index i branch original eq status
  target_index=-1
  for i in "${!FLOW[@]}"; do [[ "${FLOW[$i]}" == "$TARGET_LEVEL" ]] && target_index=$i; done
  [[ $target_index -ge 0 ]] || die "Invalid target level: $TARGET_LEVEL"

  # Original MR commits live on develop. Every later branch gets the corresponding cherry-picked commit.
  for i in $(seq 0 "$target_index"); do
    branch="${FLOW[$i]}"
    ensure_remote_branch "$branch"
    if [[ "$branch" == "develop" ]]; then
      # Use the MR commits directly. Reverting multiple commits in reverse order is safest.
      PLAN_JSON="$(jq --arg branch "$branch" --argjson commits "$(jq -c '[.[] | .id]' <<<"$MR_COMMITS_JSON")" '. + [{branch:$branch, status:"ready", commits:$commits, mode:"original"}]' <<<"$PLAN_JSON")"
    else
      local mapped=()
      while IFS= read -r original; do
        eq="$(find_equivalent_on_branch "$branch" "$original" || true)"
        [[ -n "$eq" ]] || die "Cannot safely identify cherry-picked commit for $original on $branch. Aborting before any mutation."
        mapped+=("$eq")
      done < <(jq -r '.[].id' <<<"$MR_COMMITS_JSON")
      local arr='[]' sha
      for sha in "${mapped[@]}"; do arr="$(jq --arg s "$sha" '. + [$s]' <<<"$arr")"; done
      PLAN_JSON="$(jq --arg branch "$branch" --argjson commits "$arr" '. + [{branch:$branch, status:"ready", commits:$commits, mode:"cherry-pick"}]' <<<"$PLAN_JSON")"
    fi
  done
}

print_plan() {
  printf '\n========================================\n'
  printf 'Revert plan\n'
  printf '========================================\n'
  printf 'Project : %s\n' "$PROJECT_NAME"
  printf 'MR      : !%s\n' "$MR_IID"
  printf 'Title   : %s\n' "$MR_TITLE"
  printf 'Target  : %s\n' "$TARGET_LEVEL"
  printf 'Dry run : %s\n' "$DRY_RUN"
  printf '\nBranches to revert:\n'
  jq -r '.[] | "  \(.branch) [\(.mode)]\n    " + (.commits | join("\n    "))' <<<"$PLAN_JSON"
  printf '\nNo branch will be pushed until you confirm.\n'
}

state_dir() { printf '%s/mr-%s' "$STATE_ROOT" "$MR_IID"; }

save_state() {
  local dir; dir="$(state_dir)"; mkdir -p "$dir"
  jq --arg version "$VERSION" --arg mr "$MR_IID" --arg target "$TARGET_LEVEL" --arg started "$STARTED_AT" \
     --arg project "$PROJECT_NAME" --argjson plan "$PLAN_JSON" \
     '{version:$version,mr_iid:$mr,target:$target,started_at:$started,project:$project,plan:$plan}' \
     > "$dir/plan.json"
}

create_revert_branch() {
  local branch="$1"; local source_ref="${GIT_REMOTE}/${branch}"; local revert_branch="${REVERT_BRANCH_PREFIX}/mr-${MR_IID}-${branch}-$(date '+%Y%m%d%H%M%S')"
  git fetch --quiet "$GIT_REMOTE" "$branch"
  git switch --detach --quiet "$source_ref"
  git switch --create "$revert_branch" --quiet
  printf '%s\n' "$revert_branch"
}

revert_branch() {
  local branch="$1"; local commits_json="$2"; local commit_list=() sha revert_msg
  mapfile -t commit_list < <(jq -r '.[]' <<<"$commits_json")
  local rb
  rb="$(create_revert_branch "$branch")"
  log "[$branch] created $rb"

  # Revert in reverse chronological/MR order. For merge commits, use GitLab's MR merge SHA only on develop if it is a true merge.
  local j
  for ((j=${#commit_list[@]}-1; j>=0; j--)); do
    sha="${commit_list[$j]}"
    revert_msg="Revert MR !${MR_IID}: ${MR_TITLE} (${branch})"
    local parent_count
    parent_count="$(git rev-list --parents -n1 "$sha" | awk '{print NF-1}')"
    local revert_args=(--no-edit)
    if [[ "$parent_count" -gt 1 ]]; then
      revert_args+=( -m 1 )
    fi
    if ! git revert "${revert_args[@]}" "$sha" >/tmp/revert-mr-git.out 2>&1; then
      cat /tmp/revert-mr-git.out >&2
      git revert --abort >/dev/null 2>&1 || true
      die "[$branch] conflict while reverting $sha. Revert aborted; no push performed."
    fi
  done

  git push --set-upstream "$GIT_REMOTE" "$rb" >/tmp/revert-mr-push.out 2>&1 || { cat /tmp/revert-mr-push.out >&2; die "[$branch] push failed."; }
  local mr_body="Automated revert of !${MR_IID} on **${branch}**.\n\nOriginal MR: ${MR_WEB_URL}\n\nGenerated by revert-mr.sh ${VERSION}."
  local payload
  payload="$(jq -n --arg source "$rb" --arg target "$branch" --arg title "Revert !${MR_IID} - ${branch}: ${MR_TITLE}" --arg desc "$mr_body" '{source_branch:$source,target_branch:$target,title:$title,description:$desc,remove_source_branch:false}')"
  local new_mr
  new_mr="$(api POST "/projects/${PROJECT_ID}/merge_requests" "$payload")" || die "[$branch] branch pushed but creating GitLab MR failed. Create the MR manually from $rb -> $branch."
  printf '%s\n' "$(json_get_opt '.web_url' <<<"$new_mr")"
}

main() {
  require_cmd git; require_cmd curl; require_cmd jq
  load_env
  : "${GITLAB_URL:?GITLAB_URL is required}"; : "${GITLAB_TOKEN:?GITLAB_TOKEN is required}"
  GIT_REMOTE="${GIT_REMOTE:-origin}"
  BRANCH_FLOW="${BRANCH_FLOW:-develop staging demo_pkg uat main}"
  REVERT_BRANCH_PREFIX="${REVERT_BRANCH_PREFIX:-revert}"
  DRY_RUN="${DRY_RUN:-true}"
  CREATE_MR="${CREATE_MR:-true}"
  STARTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  normalize_flow
  check_local_repo

  printf '\nGitLab MR Revert Tool v%s\n\n' "$VERSION"
  local mr_url
  read -r -p 'GitLab Merge Request URL: ' mr_url
  [[ -n "$mr_url" ]] || die 'MR URL is required.'
  parse_mr_url "$mr_url"

  printf '\nRevert target:\n'
  printf '  1) develop\n  2) staging\n  3) demo_pkg\n  4) uat\n  5) main\n'
  local choice
  read -r -p 'Select [1-5]: ' choice
  case "$choice" in 1) TARGET_LEVEL=develop;;2) TARGET_LEVEL=staging;;3) TARGET_LEVEL=demo_pkg;;4) TARGET_LEVEL=uat;;5) TARGET_LEVEL=main;;*) die 'Invalid target.';; esac

  fetch_project; fetch_mr; get_mr_commits; find_original_commits; build_plan; save_state; print_plan

  [[ "$DRY_RUN" == "true" ]] && { printf '\nDRY RUN complete. Set DRY_RUN=false in .env (or export it) to execute.\n'; return 0; }
  confirm 'Execute this revert plan?' || { printf 'Cancelled. No mutation performed.\n'; return 0; }

  local results_dir; results_dir="$(state_dir)/results"; mkdir -p "$results_dir"
  local branch commits mr_url_out
  while IFS=$'\t' read -r branch commits; do
    log "[$branch] reverting..."
    mr_url_out="$(revert_branch "$branch" "$commits")"
    printf '%s\n' "$mr_url_out" > "$results_dir/${branch}.mr-url"
    log "[$branch] Revert MR: $mr_url_out"
  done < <(jq -r '.[] | [.branch,(.commits|tojson)] | @tsv' <<<"$PLAN_JSON")

  # Only after every requested branch has been reverted and its Revert MR created,
  # replace ALL labels on the original MR with the single `Reverted` label.
  replace_mr_labels_with_reverted

  printf '\nAll requested revert branches/MRs created successfully.\n'
  printf 'Original MR !%s labels: Reverted\n' "$MR_IID"
  printf 'State: %s\n' "$(state_dir)"
}

main "$@"
