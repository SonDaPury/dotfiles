#!/usr/bin/env bash

git_require_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || utils_die "Current directory is not a Git repository"
}

git_require_clean_worktree() {
  git diff --quiet || utils_die "Working tree has unstaged changes; commit or stash them first"
  git diff --cached --quiet || utils_die "Working tree has staged changes; commit or stash them first"
}

git_current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null || true
}

git_fetch_origin() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    logger_debug "Would run: git fetch origin --prune"
    return 0
  fi
  git fetch origin --prune
}

git_remote_branch_exists() {
  local branch="$1"
  git show-ref --verify --quiet "refs/remotes/origin/$branch"
}

git_sync_branch() {
  local branch="$1"
  git_remote_branch_exists "$branch" || utils_die "Remote branch does not exist: origin/$branch"

  if [[ "${DRY_RUN:-false}" == true ]]; then
    logger_debug "Would create/reset local branch: $branch -> origin/$branch"
    return 0
  fi

  # -B is deterministic: it creates the local branch if missing and otherwise
  # resets it to the remote ref. Untracked files are intentionally untouched.
  git checkout -B "$branch" "origin/$branch"
  git reset --hard "origin/$branch"
}

git_restore_branch() {
  local branch="$1"
  [[ -n "$branch" ]] || return 0
  [[ "${DRY_RUN:-false}" != true ]] || return 0
  git checkout --quiet "$branch"
}
