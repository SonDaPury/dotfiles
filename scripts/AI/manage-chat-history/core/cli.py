import argparse
import json
import sys
from pathlib import Path
from typing import Optional
from core.manager import SessionManager
from core.platform_utils import format_relative_time, truncate_text, CYAN, GREEN, YELLOW, RED, RESET, BOLD

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="manage_chat",
        description="Quản lý lịch sử chat của các AI CLI (Antigravity, Claude Code, Codex)"
    )
    subparsers = parser.add_subparsers(dest="subcommand", help="Lệnh thực thi")

    # Command: list
    list_p = subparsers.add_parser("list", help="Liệt kê danh sách các phiên chat")
    list_p.add_argument("--provider", "-p", choices=["all", "agy", "claude", "codex"], default="all", help="Lọc theo AI provider")
    list_p.add_argument("--cwd", "-c", action="store_true", help="Chỉ hiện chat trong workspace hiện tại")
    list_p.add_argument("--query", "-q", help="Tìm kiếm từ khóa theo tiêu đề hoặc workspace")
    list_p.add_argument("--json", action="store_true", help="Xuất kết quả định dạng JSON")
    list_p.add_argument("--limit", "-n", type=int, default=50, help="Giới hạn số lượng phiên hiển thị")

    # Command: show
    show_p = subparsers.add_parser("show", help="Xem chi tiết một phiên chat")
    show_p.add_argument("id", help="ID phiên chat")
    show_p.add_argument("--provider", "-p", default="agy", help="Provider (mặc định: agy)")

    # Command: resume
    resume_p = subparsers.add_parser("resume", help="Tiếp tục phiên chat")
    resume_p.add_argument("id", help="ID phiên chat")
    resume_p.add_argument("--provider", "-p", default="agy", help="Provider (mặc định: agy)")

    # Command: delete
    del_p = subparsers.add_parser("delete", help="Xóa phiên chat")
    del_p.add_argument("ids", nargs="+", help="Danh sách ID phiên chat cần xóa")
    del_p.add_argument("--provider", "-p", default="agy", help="Provider (mặc định: agy)")
    del_p.add_argument("--yes", "-y", action="store_true", help="Bỏ qua bước hỏi xác nhận")

    return parser

def handle_cli(args: argparse.Namespace, manager: SessionManager) -> int:
    cmd = args.subcommand

    if cmd == "list":
        sessions = manager.list_sessions(
            provider_name=args.provider,
            cwd_only=args.cwd,
            search_query=args.query
        )
        sessions = sessions[:args.limit]

        if args.json:
            data = [{
                "id": s.id,
                "provider": s.provider,
                "title": s.title,
                "preview": s.preview,
                "last_modified": s.last_modified.isoformat(),
                "step_count": s.step_count,
                "workspaces": [str(p) for p in s.workspace_paths]
            } for s in sessions]
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return 0

        if not sessions:
            print("Không tìm thấy phiên chat nào.")
            return 0

        print(f"{BOLD}{'PROVIDER':<8} {'ID':<18} {'MODIFIED':<16} {'STEPS':<6} {'TITLE'}{RESET}")
        print("-" * 80)
        for s in sessions:
            ws_hint = f" ({s.workspace_paths[0].name})" if s.workspace_paths else ""
            title_display = truncate_text(s.title + ws_hint, 40)
            time_display = format_relative_time(s.last_modified)
            print(f"{CYAN}{s.provider:<8}{RESET} {s.id[:16]:<18} {time_display:<16} {s.step_count:<6} {title_display}")
        return 0

    elif cmd == "show":
        details = manager.get_session_details(args.provider, args.id)
        if not details:
            print(f"{RED}Không tìm thấy phiên chat '{args.id}' thuộc provider '{args.provider}'.{RESET}")
            return 1
        s = details.session
        print(f"{BOLD}ID:{RESET}         {s.id}")
        print(f"{BOLD}Provider:{RESET}   {s.provider_display}")
        print(f"{BOLD}Tiêu đề:{RESET}    {s.title}")
        print(f"{BOLD}Cập nhật:{RESET}   {s.last_modified}")
        print(f"{BOLD}Số bước:{RESET}    {s.step_count}")
        print(f"{BOLD}Workspace:{RESET}  {', '.join(str(p) for p in s.workspace_paths)}")
        print(f"\n{BOLD}Nội dung gần nhất:{RESET}")
        for msg in details.messages_snippet:
            print(f"  {msg}")
        return 0

    elif cmd == "resume":
        sessions = manager.list_sessions(provider_name=args.provider)
        target = next((s for s in sessions if s.id.startswith(args.id)), None)
        if not target:
            print(f"{RED}Không tìm thấy phiên chat với ID bắt đầu bằng '{args.id}'.{RESET}")
            return 1
        print(f"{GREEN}Đang tiếp tục phiên chat: {target.title} ({target.id})...{RESET}")
        manager.resume_session(target)
        return 0

    elif cmd == "delete":
        target_ids = args.ids
        if not args.yes:
            ans = input(f"Bạn có chắc muốn xóa vĩnh viễn {len(target_ids)} phiên chat? [y/N]: ").strip().lower()
            if ans not in ('y', 'yes'):
                print("Đã hủy thao tác xóa.")
                return 0

        results = manager.delete_sessions({args.provider: target_ids})
        total_succeeded = sum(len(r.succeeded_ids) for r in results)
        total_failed = sum(len(r.failed_ids) for r in results)
        print(f"{GREEN}Đã xóa thành công {total_succeeded} phiên.{RESET}")
        if total_failed > 0:
            for r in results:
                for err in r.error_messages:
                    print(f"{RED}{err}{RESET}")
        return 0

    return 0
