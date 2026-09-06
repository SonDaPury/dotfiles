#!/usr/bin/env bash
set -Eeuo pipefail

readonly TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd -- "$TEST_DIR/.." && pwd)"

# shellcheck source=../lib/utils.sh
source "$ROOT_DIR/lib/utils.sh"
# shellcheck source=../lib/logger.sh
source "$ROOT_DIR/lib/logger.sh"
# shellcheck source=../lib/merge-rule.sh
source "$ROOT_DIR/lib/merge-rule.sh"
# shellcheck source=../lib/gitlab-api.sh
source "$ROOT_DIR/lib/gitlab-api.sh"
# shellcheck source=../lib/merge-request.sh
source "$ROOT_DIR/lib/merge-request.sh"

LOGGER_FILE="/private/tmp/gitlab-auto-merge-tests.log"
: > "$LOGGER_FILE"
DRY_RUN=false
AUTO_MERGE=true
DELETE_SOURCE_BRANCH=false
RETRY_COUNT=0
RETRY_INTERVAL=0
VERBOSE=false

gitlab_api_get_open_merge_request() { GITLAB_API_BODY=null; }
gitlab_api_create_merge_request() { GITLAB_API_BODY='{"iid":42,"web_url":"https://gitlab.example/mr/42"}'; }
gitlab_api_get_merge_request() { GITLAB_API_BODY='{"iid":42,"web_url":"https://gitlab.example/mr/42","detailed_merge_status":"conflict","changes_count":null,"has_conflicts":true}'; }
gitlab_api_get_merge_request_changes() { GITLAB_API_BODY='{"changes":[]}'; }
gitlab_api_get_merge_request_commits() { GITLAB_API_BODY='[]'; }
gitlab_api_close_merge_request() { return 0; }
gitlab_api_merge_merge_request() { return 0; }

merge_request_init
merge_request_process_rule 'main:develop'
[[ "$MR_STATUS" == NO_CHANGE_TO_MERGE ]]
[[ "$MR_NO_CHANGE_COUNT" == 1 ]]

gitlab_api_get_open_merge_request() { GITLAB_API_BODY='{"iid":43,"web_url":"https://gitlab.example/mr/43"}'; }
gitlab_api_get_merge_request() { GITLAB_API_BODY='{"iid":43,"web_url":"https://gitlab.example/mr/43","detailed_merge_status":"conflict","changes_count":"1","has_conflicts":true}'; }
gitlab_api_get_merge_request_changes() { GITLAB_API_BODY='{"changes":[{"new_path":"example.txt"}]}'; }
merge_request_init
if merge_request_process_rule 'main:staging'; then
  printf '%s\n' 'Expected conflict workflow to return non-zero' >&2
  exit 1
fi
[[ "$MR_STATUS" == CONFLICT_CLOSED ]]
[[ "$MR_EXIT_CODE" == 2 ]]

printf '%s\n' 'Offline merge-request tests: OK'
