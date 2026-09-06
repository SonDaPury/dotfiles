#!/bin/bash

# commit bạn muốn đổi hash (có thể là HEAD hoặc commit hash cụ thể)
TARGET_COMMIT=${1:-HEAD}

# Lấy full commit message (subject + body)
COMMIT_MSG=$(git log -1 --format=%B "$TARGET_COMMIT")

# Reset mềm về trước commit
git reset --soft "$TARGET_COMMIT~1"

# Commit lại với message + description cũ
git commit -m "$COMMIT_MSG"
