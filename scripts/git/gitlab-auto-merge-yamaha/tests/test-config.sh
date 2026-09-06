#!/usr/bin/env bash
set -Eeuo pipefail

readonly TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd -- "$TEST_DIR/.." && pwd)"
readonly TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

# shellcheck source=../lib/utils.sh
source "$ROOT_DIR/lib/utils.sh"
# shellcheck source=../lib/config.sh
source "$ROOT_DIR/lib/config.sh"

printf '%s\n' 'GITLAB_TOKEN=test-token-from-local-env' > "$TEMP_DIR/.env.local"
chmod 600 "$TEMP_DIR/.env.local"

cat > "$TEMP_DIR/project.conf" <<EOF
GITLAB_ENV_FILE="$TEMP_DIR/.env.local"
EOF

unset GITLAB_TOKEN
config_load "$TEMP_DIR/project.conf"
[[ "$GITLAB_TOKEN" == test-token-from-local-env ]]

printf '%s\n' 'Local GitLab secret config tests: OK'
