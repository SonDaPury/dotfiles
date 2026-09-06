#!/bin/bash

set -e

INPUT_FILE="$SCRIPT_DIR/$INPUT_FILE"
LOG_FILE="$SCRIPT_DIR/$LOG_FILE"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.gitlab-revert.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Không tìm thấy config file"
  exit 1
fi

source $CONFIG_FILE

echo "===== START $(date) =====" | tee -a $LOG_FILE

# update base branch
git checkout $BASE_BRANCH
git pull $REMOTE $BASE_BRANCH

while IFS= read -r url
do
  [[ -z "$url" ]] && continue

  echo "------------------------" | tee -a $LOG_FILE
  echo "👉 URL: $url" | tee -a $LOG_FILE

  # Extract MR IID
  MR_IID=$(echo "$url" | grep -oE '[0-9]+$')

  # Extract PROJECT_PATH từ URL
  PROJECT_PATH=$(echo "$url" | sed -E 's|https?://[^/]+/([^/]+/.+)/-/merge_requests/[0-9]+|\1|')

  # Encode path
  ENCODED_PATH=$(echo "$PROJECT_PATH" | sed 's/\//%2F/g')

  echo "📦 Project: $PROJECT_PATH" | tee -a $LOG_FILE
  echo "🔢 MR: !${MR_IID}" | tee -a $LOG_FILE

  # Get MR data
  MR_DATA=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$ENCODED_PATH/merge_requests/$MR_IID")

  MERGE_COMMIT=$(echo "$MR_DATA" | jq -r '.merge_commit_sha')

  if [[ "$MERGE_COMMIT" == "null" || -z "$MERGE_COMMIT" ]]; then
    echo "❌ MR chưa merge hoặc không có commit" | tee -a $LOG_FILE
    continue
  fi

  BRANCH_NAME="revert-mr-${MR_IID}"

  # Check branch exists
  if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    echo "⚠️ Branch đã tồn tại, skip" | tee -a $LOG_FILE
    continue
  fi

  # Create branch
  git checkout -b $BRANCH_NAME

  # Revert
  if ! git revert -m 1 $MERGE_COMMIT --no-edit; then
    echo "⚠️ Conflict xảy ra, cần resolve tay" | tee -a $LOG_FILE
    git checkout $BASE_BRANCH
    git branch -D $BRANCH_NAME
    continue
  fi

  # Push
  git push $REMOTE $BRANCH_NAME

  # Create MR
  CREATE_MR=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data "source_branch=$BRANCH_NAME" \
    --data "target_branch=$BASE_BRANCH" \
    --data-urlencode "title=Revert MR !${MR_IID}" \
    "$GITLAB_URL/api/v4/projects/$ENCODED_PATH/merge_requests")

  MR_URL=$(echo "$CREATE_MR" | jq -r '.web_url')

  if [[ "$MR_URL" == "null" || -z "$MR_URL" ]]; then
    echo "❌ Không tạo được MR" | tee -a $LOG_FILE
  else
    echo "✅ Created MR: $MR_URL" | tee -a $LOG_FILE
  fi

  git checkout $BASE_BRANCH

done < "$INPUT_FILE"

echo "===== END $(date) =====" | tee -a $LOG_FILE
