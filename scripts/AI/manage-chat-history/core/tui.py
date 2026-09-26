import sys
import os
from pathlib import Path
from typing import List, Set, Optional
from core.manager import SessionManager
from core.models import Session
from core.platform_utils import (
    get_key, get_terminal_size, enter_alt_screen, exit_alt_screen,
    clear_screen, init_terminal, format_relative_time, truncate_text,
    RESET, BOLD, DIM, CYAN, GREEN, YELLOW, RED, BLUE, BG_BLUE, BG_GRAY
)

class TerminalUI:
    def __init__(self, manager: SessionManager):
        self.manager = manager
        self.provider_filter: str = "all"
        self.cwd_only: bool = False
        self.search_query: str = ""
        self.sessions: List[Session] = []
        self.selected_index: int = 0
        self.scroll_offset: int = 0
        self.marked_ids: Set[str] = set()
        self.status_message: str = ""
        self.status_is_error: bool = False
        self.reload_sessions()

    def reload_sessions(self) -> None:
        self.sessions = self.manager.list_sessions(
            provider_name=self.provider_filter,
            cwd_only=self.cwd_only,
            search_query=self.search_query
        )
        if self.selected_index >= len(self.sessions):
            self.selected_index = max(0, len(self.sessions) - 1)

    def move_up(self) -> None:
        if self.selected_index > 0:
            self.selected_index -= 1
            if self.selected_index < self.scroll_offset:
                self.scroll_offset = self.selected_index

    def move_down(self) -> None:
        if self.selected_index < len(self.sessions) - 1:
            self.selected_index += 1

    def toggle_select(self) -> None:
        if not self.sessions: return
        sid = self.sessions[self.selected_index].id
        if sid in self.marked_ids:
            self.marked_ids.remove(sid)
        else:
            self.marked_ids.add(sid)

    def select_all(self) -> None:
        if not self.sessions: return
        all_visible_ids = {s.id for s in self.sessions}
        if self.marked_ids >= all_visible_ids:
            self.marked_ids.clear()
        else:
            self.marked_ids.update(all_visible_ids)

    def cycle_provider(self) -> None:
        providers = ["all"] + [p.name for p in self.manager.get_available_providers()]
        idx = providers.index(self.provider_filter) if self.provider_filter in providers else 0
        self.provider_filter = providers[(idx + 1) % len(providers)]
        self.reload_sessions()

    def toggle_cwd(self) -> None:
        self.cwd_only = not self.cwd_only
        self.reload_sessions()

    def render(self) -> None:
        cols, rows = get_terminal_size()
        clear_screen()

        # 1. Header
        prov_label = self.provider_filter.upper()
        scope_label = "WORKSPACE HIỆN TẠI" if self.cwd_only else "TẤT CẢ WORKSPACES"
        header = f" {BOLD}AI Chat History Manager{RESET} ── Provider: [{CYAN}{prov_label}{RESET}] ── Phạm vi: [{YELLOW}{scope_label}{RESET}]"
        sys.stdout.write(header[:cols] + "\n")

        # 2. Search / Status Line
        if self.search_query:
            search_line = f" Tìm kiếm (/): {GREEN}{self.search_query}{RESET} ({len(self.sessions)} kết quả)"
        elif self.status_message:
            color = RED if self.status_is_error else GREEN
            search_line = f" {color}{self.status_message}{RESET}"
        else:
            search_line = f" {DIM}Nhấn '/' để tìm kiếm, '?' để xem trợ giúp phím tắt{RESET}"
        sys.stdout.write(search_line[:cols] + "\n")
        sys.stdout.write("─" * cols + "\n")

        # 3. Main Area: Left (Session list) | Right (Preview)
        content_height = max(5, rows - 6)
        list_width = max(35, int(cols * 0.52))
        preview_width = cols - list_width - 3

        if self.selected_index >= self.scroll_offset + content_height:
            self.scroll_offset = self.selected_index - content_height + 1
        if self.selected_index < self.scroll_offset:
            self.scroll_offset = self.selected_index

        current_session = self.sessions[self.selected_index] if self.sessions else None
        details = None
        if current_session:
            details = self.manager.get_session_details(current_session.provider, current_session.id)

        for i in range(content_height):
            idx = self.scroll_offset + i
            # Left pane line
            if idx < len(self.sessions):
                s = self.sessions[idx]
                is_cur = (idx == self.selected_index)
                is_marked = s.id in self.marked_ids
                mark_str = "[x]" if is_marked else "[ ]"
                cursor_str = ">" if is_cur else " "
                time_str = format_relative_time(s.last_modified)
                ws_name = f"({s.workspace_paths[0].name})" if s.workspace_paths else ""

                avail_title = max(10, list_width - len(time_str) - 16)
                title_str = truncate_text(f"{s.title} {ws_name}", avail_title)

                left_raw = f"{cursor_str}{mark_str} {title_str:<{avail_title}} {time_str} ({s.provider})"
                if is_cur:
                    left_line = f"{BG_GRAY}{BOLD}{left_raw[:list_width]:<{list_width}}{RESET}"
                elif is_marked:
                    left_line = f"{YELLOW}{left_raw[:list_width]:<{list_width}}{RESET}"
                else:
                    left_line = f"{left_raw[:list_width]:<{list_width}}"
            else:
                left_line = " " * list_width

            # Right pane line
            right_line = ""
            if current_session:
                if i == 0:
                    right_line = f"{BOLD}ID:{RESET} {current_session.id}"
                elif i == 1:
                    right_line = f"{BOLD}Tiêu đề:{RESET} {truncate_text(current_session.title, preview_width - 10)}"
                elif i == 2:
                    right_line = f"{BOLD}Provider:{RESET} {current_session.provider_display}"
                elif i == 3:
                    ws_str = str(current_session.workspace_paths[0]) if current_session.workspace_paths else "N/A"
                    right_line = f"{BOLD}Thư mục:{RESET} {truncate_text(ws_str, preview_width - 10)}"
                elif i == 4:
                    right_line = f"{BOLD}Cập nhật:{RESET} {current_session.last_modified.strftime('%Y-%m-%d %H:%M:%S')} ({current_session.step_count} bước)"
                elif i == 5:
                    right_line = "─" * preview_width
                elif i >= 6:
                    snippet_idx = i - 6
                    if details and snippet_idx < len(details.messages_snippet):
                        right_line = truncate_text(details.messages_snippet[snippet_idx], preview_width)

            sys.stdout.write(f"{left_line} │ {right_line[:preview_width]}\n")

        # 4. Footer shortcuts bar
        sys.stdout.write("─" * cols + "\n")
        del_count = len(self.marked_ids) if self.marked_ids else 1
        footer = f" [Enter] Vào chat  [Space] Chọn  [d] Xóa ({del_count})  [w] Workspace  [p] Provider  [/] Tìm  [q] Thoát"
        sys.stdout.write(f"{DIM}{footer[:cols]}{RESET}\n")
        sys.stdout.flush()

    def prompt_search(self) -> None:
        exit_alt_screen()
        try:
            val = input("Nhập từ khóa tìm kiếm (bỏ trống để hủy): ").strip()
            self.search_query = val
            self.reload_sessions()
        finally:
            enter_alt_screen()

    def confirm_and_delete(self) -> None:
        to_delete = list(self.marked_ids) if self.marked_ids else ([self.sessions[self.selected_index].id] if self.sessions else [])
        if not to_delete: return

        exit_alt_screen()
        try:
            print(f"\n{YELLOW}CẢNH BÁO: Bạn chuẩn bị xóa vĩnh viễn {len(to_delete)} phiên chat.{RESET}")
            ans = input("Xác nhận xóa? [y/N]: ").strip().lower()
            if ans in ('y', 'yes'):
                by_prov = {}
                for s in self.sessions:
                    if s.id in to_delete:
                        by_prov.setdefault(s.provider, []).append(s.id)
                results = self.manager.delete_sessions(by_prov)
                succeeded = sum(len(r.succeeded_ids) for r in results)
                self.marked_ids.clear()
                self.status_message = f"Đã xóa thành công {succeeded} phiên chat."
                self.status_is_error = False
                self.reload_sessions()
            else:
                self.status_message = "Đã hủy thao tác xóa."
                self.status_is_error = False
        finally:
            enter_alt_screen()

    def resume_current(self) -> None:
        if not self.sessions: return
        target = self.sessions[self.selected_index]
        exit_alt_screen()
        try:
            print(f"\n{GREEN}Đang mở phiên chat: {target.title}...{RESET}")
            self.manager.resume_session(target)
        except Exception as e:
            print(f"{RED}Lỗi khi mở phiên chat: {e}{RESET}")
            input("Nhấn Enter để quay lại...")
        finally:
            enter_alt_screen()
            self.reload_sessions()

    def run(self) -> None:
        init_terminal()
        enter_alt_screen()
        try:
            while True:
                self.render()
                key = get_key()
                if key in ('q', 'ESC'):
                    break
                elif key in ('UP', 'k'):
                    self.move_up()
                elif key in ('DOWN', 'j'):
                    self.move_down()
                elif key == 'PAGE_UP':
                    for _ in range(10): self.move_up()
                elif key == 'PAGE_DOWN':
                    for _ in range(10): self.move_down()
                elif key == 'HOME':
                    self.selected_index = 0
                elif key == 'END':
                    self.selected_index = max(0, len(self.sessions) - 1)
                elif key == 'SPACE':
                    self.toggle_select()
                elif key == 'a':
                    self.select_all()
                elif key in ('p', 'TAB'):
                    self.cycle_provider()
                elif key == 'w':
                    self.toggle_cwd()
                elif key == 'r':
                    self.reload_sessions()
                    self.status_message = "Đã làm mới dữ liệu."
                elif key == '/':
                    self.prompt_search()
                elif key in ('d', 'x', 'DELETE'):
                    self.confirm_and_delete()
                elif key == 'ENTER':
                    self.resume_current()
        finally:
            exit_alt_screen()
