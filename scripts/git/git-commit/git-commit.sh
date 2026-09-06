#!/usr/bin/env bash
set -euo pipefail

# --- 1) Emoji mapping + types ---
declare -A emoji_map=(
  [feat]="✨" [fix]="🐛" [docs]="📝" [style]="💄" [refactor]="♻️"
  [test]="✅" [chore]="🔧" [build]="🏗️" [perf]="⚡" [ci]="👷" [revert]="⏪"
)

types=(feat fix docs style refactor test chore build perf ci revert)

# --- 2) Hiển thị menu chọn loại commit ---
echo "-----------------------"
echo "Chọn loại commit:"
for i in "${!types[@]}"; do
  t="${types[$i]}"
  printf "%2d) %-10s %s\n" $((i + 1)) "$t" "${emoji_map[$t]}"
done
echo "-----------------------"

while true; do
  read -e -r -p "Nhập số tương ứng với loại commit: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#types[@]})); then
    type="${types[$((choice - 1))]}"
    break
  else
    echo "❌ Lựa chọn không hợp lệ."
  fi
done
emoji="${emoji_map[$type]}"

# --- 3) Scope ---
read -e -r -p "Nhập tên module (ví dụ: login, product)... (Enter để bỏ qua): " scope
[[ -n "$scope" ]] && scope="($scope)"

# --- 4) Summary ---
while true; do
  read -e -r -p "Nhập mô tả ngắn gọn (Summary, < 100 ký tự): " message
  if [[ -z "$message" ]]; then
    echo "⚠️  Mô tả không được để trống."
  elif [[ ${#message} -gt 100 ]]; then
    echo "⚠️  Mô tả quá dài. Vui lòng viết ngắn lại."
  else
    break
  fi
done

# --- 5) Description (mở editor Git mặc định) ---
TMP_DESC="$(mktemp)"
printf "# Nhập mô tả chi tiết bên dưới. Các dòng bắt đầu bằng # sẽ bị bỏ qua.\n" >"$TMP_DESC"

GIT_EDITOR_CMD=$(git var GIT_EDITOR 2>/dev/null || true)
EDITOR_CMD="${GIT_EDITOR_CMD:-${EDITOR:-vim}}"

"$EDITOR_CMD" "$TMP_DESC" || true

detailed_message="$(grep -v '^[[:space:]]*#' "$TMP_DESC" || true)"
rm -f "$TMP_DESC"

# --- 6) Ghép commit message ---
summary="${type}${scope}: ${emoji} ${message}"
if [[ -n "${detailed_message//[[:space:]]/}" ]]; then
  commit_content="$summary"$'\n\n'"$detailed_message"
else
  commit_content="$summary"
fi

# --- 7) Lưu & commit ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_MSG_FILE="$SCRIPT_DIR/.last-commit-msg"
printf "%s\n" "$commit_content" >"$COMMIT_MSG_FILE"

echo ""
echo "✅ Commit message được tạo:"
echo "---------------------------"
cat "$COMMIT_MSG_FILE"
echo "---------------------------"

read -e -r -p "Bạn có muốn commit ngay không? [Y/n]: " confirm
confirm=${confirm:-y}
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  git commit -F "$COMMIT_MSG_FILE"
else
  echo "📌 Bạn có thể commit lại bằng lệnh:"
  echo "git commit -F \"$COMMIT_MSG_FILE\""
fi
