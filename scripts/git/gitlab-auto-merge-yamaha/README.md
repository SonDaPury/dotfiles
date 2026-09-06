# GitLab Auto Merge

This Bash CLI prepares local branches for a GitLab merge-request workflow.
It is designed around configurable `source:target` rules, so a project can use
any promotion path without changing the scripts.

## Current scope (Phase 1–5)

The current implementation:

- loads and validates a Bash config file;
- overwrites one log file on every run;
- parses and de-duplicates all branches in `MERGE_RULES`;
- switches to the configured local repository;
- fetches `origin` with `--prune`;
- creates or resets local branches to their matching `origin/<branch>` ref;
- returns to the branch that was checked out before the run.
- provides a GitLab REST API module for project checks and Merge Request
  lookup, creation, refresh, merge, close, and source-branch deletion.
- processes every `MERGE_RULE`: reuses an existing MR or creates one, waits for
  GitLab's merge check, closes genuine conflicts, reports `NO_CHANGE_TO_MERGE`
  for MRs with both zero changed files and zero commits, and merges mergeable MRs
  when `AUTO_MERGE=true`.

`--dry-run` never calls the GitLab API. It reports the rule actions that would
be evaluated after local branch synchronization.

Before a real run, the tool verifies that the token can access `PROJECT_ID`.
If that check fails, it does not alter branches or Merge Requests.

## Requirements

- Bash 4 or newer (macOS users may need a newer Bash than the system default)
- `git`
- `curl` and `jq` (validated now because they are required by the next API phase)
- a local Git repository with an `origin` remote

## Configure

Copy the provided config and replace the values for the project:

```bash
cp config/yamaha_imp.conf config/my-project.local.conf
```

Keep the token in a local env file outside version control:

```bash
GITLAB_ENV_FILE="/absolute/path/to/.env.local"
```

The env file must contain only the secret entry needed by this tool:

```dotenv
GITLAB_TOKEN=replace_with_your_gitlab_personal_access_token
```

An already-exported `GITLAB_TOKEN` takes precedence. Use a token with the API
scope and project permissions required to read, create, and merge MRs.

`MERGE_RULES` contains one `source:target` value per promotion path:

```bash
MERGE_RULES=(
  "main:staging"
  "staging:develop"
)
```

`LOCAL_REPO_PATH` is the absolute path to the local clone for this project. It
is required, so the centralized script can be called from any directory:

```bash
LOCAL_REPO_PATH="/Users/you/Workspaces/projects/my-project"
```

The workflow synchronizes the unique branch set (`main`, `staging`, and
`develop` in this example), then processes every rule in the listed order.
With `AUTO_MERGE=false`, mergeable MRs remain open. `DELETE_SOURCE_BRANCH=true`
asks GitLab to delete the source branch after a successful merge; use it with
care for shared branches such as `main`.

`GITLAB_API_TIMEOUT` and `GITLAB_API_CONNECT_TIMEOUT` limit one API request in
seconds (defaults: 30 and 10). They prevent a network problem from leaving the
automation stuck indefinitely.

`COLOR_OUTPUT=auto` uses colored console output only in an interactive
terminal. Set it to `true` to force color or `false` to disable it. Saved logs
always remain plain text, but include icons and structured rule blocks.

`LOG_FILE` is resolved relative to the selected config file. The shipped config
uses `../logs/merge.log`, which places the log in this project's `logs/` folder.

## Run

Run the command from any directory; the script changes into `LOCAL_REPO_PATH`
before it performs Git operations:

```bash
/path/to/gitlab-auto-merge/merge-sync.sh --config /path/to/gitlab-auto-merge/config/my-project.local.conf
```

Use a dry run to inspect the branches first:

```bash
/path/to/gitlab-auto-merge/merge-sync.sh --config /path/to/gitlab-auto-merge/config/my-project.local.conf --dry-run --verbose
```

### Make shortcuts

The included Yamaha IMP configuration can be run from the tool directory with:

```bash
make pull-imp
```

Preview it without changing local branches:

```bash
make pull-imp-dry-run
```

Run the offline test suite:

```bash
make test
```

The tool refuses to start if tracked files have staged or unstaged changes,
because it uses `git checkout -B` and `git reset --hard` to make local branches
exactly match the remote. Untracked files are deliberately left alone.

## Log

Every run overwrites the configured log file. It records each rule's MR URL,
result, and reason, followed by a summary. The command returns a non-zero exit
code when a conflict, timeout, blocked MR, or API failure needs attention:

- `2`: a conflict was closed or an MR is blocked;
- `3`: GitLab kept checking mergeability past the retry limit;
- `4`: GitLab API or merge operation failed.

## Project layout

```text
merge-sync.sh       Command entry point
config/             Per-project Bash configuration
lib/config.sh       Load and validate config
lib/logger.sh       Console and overwrite-file logging
lib/merge-rule.sh   `source:target` parsing
lib/git.sh          Local Git synchronization
lib/gitlab-api.sh   GitLab REST API client
lib/merge-request.sh MR workflow, retry, merge and close decisions
logs/               Runtime log location
```
