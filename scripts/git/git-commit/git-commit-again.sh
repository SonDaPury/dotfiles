#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_MSG_FILE="$SCRIPT_DIR/.last-commit-msg"

if [[ ! -f "$COMMIT_MSG_FILE" ]]; then
  echo "❌ Không tìm thấy file commit message: $COMMIT_MSG_FILE"
  echo "👉 Bạn cần chạy script tạo commit trước (git-commit.sh)"
  exit 1
fi

echo "📦 Đang commit lại với message từ:"
echo "$COMMIT_MSG_FILE"
echo ""

git commit -F "$COMMIT_MSG_FILE"
