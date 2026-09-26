# AI Chat History Manager

Công cụ CLI và Terminal UI (TUI) đa nền tảng (macOS, Linux, Windows) để quản lý lịch sử chat của các AI CLI (Antigravity `agy`, Claude Code, Codex).

## Tính năng

- **Interactive TUI**: Giao diện terminal đầy đủ tính năng, tương tác phím tắt mượt mà.
- **Xem & Resume**: Xem trước tin nhắn, nhấn Enter để mở lại phiên làm việc đúng trong workspace của nó.
- **Xóa an toàn**: Chọn 1 hoặc nhiều phiên (`Space`) để dọn sạch dữ liệu (SQLite, conversations, artifacts) kèm hộp thoại xác nhận `[y/N]`.
- **Đa nền tảng & 0 Dependencies**: 100% Python Standard Library (không cần cài thêm `pip`).
- **Mở rộng dễ dàng**: Thiết kế Provider Pattern cho Antigravity CLI, Claude Code, Codex.

## Phím tắt trong TUI

- `↑` / `k`, `↓` / `j`: Di chuyển lên / xuống
- `Space`: Chọn / bỏ chọn (đánh dấu `[x]`)
- `a`: Chọn tất cả / bỏ chọn tất cả
- `Enter`: Tiếp tục phiên chat (Resume)
- `d` hoặc `x`: Xóa các phiên đã chọn (có xác nhận `[y/N]`)
- `/`: Tìm kiếm theo từ khóa
- `w`: Lọc theo thư mục hiện tại (CWD)
- `p` / `Tab`: Chuyển đổi xem theo Provider (ALL / Antigravity / Claude Code / Codex)
- `r`: Làm mới danh sách
- `q` / `Esc`: Thoát

## Sử dụng dòng lệnh (Scripting)

```bash
# Xem danh sách
python3 manage_chat.py list
python3 manage_chat.py list --cwd
python3 manage_chat.py list --json
python3 manage_chat.py list --query "bài tập"

# Xem chi tiết một phiên
python3 manage_chat.py show <session_id>

# Tiếp tục một phiên
python3 manage_chat.py resume <session_id>

# Xóa phiên chat
python3 manage_chat.py delete <session_id...> [-y]
```

## Tích hợp Shell (Dotfiles Alias)

Thêm alias vào `.zshrc` hoặc `.bashrc`:

```bash
alias chat-history="python3 /Users/son/Workspaces/dotfiles/scripts/AI/manage-chat-history/manage_chat.py"
```
