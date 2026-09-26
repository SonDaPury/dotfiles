#!/usr/bin/env python3
"""
AI Chat History Manager
Unified CLI and Interactive TUI to manage chat sessions across Antigravity, Claude Code, and Codex.
"""
import sys
from pathlib import Path

# Ensure package directory is in sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from core.manager import SessionManager
from core.cli import build_parser, handle_cli
from core.tui import TerminalUI

def main():
    manager = SessionManager()
    parser = build_parser()

    # If no arguments provided, launch interactive Terminal UI
    if len(sys.argv) == 1:
        tui = TerminalUI(manager)
        try:
            tui.run()
        except KeyboardInterrupt:
            pass
        sys.exit(0)

    # Otherwise parse and handle subcommand
    args = parser.parse_args()
    if not args.subcommand:
        parser.print_help()
        sys.exit(0)

    exit_code = handle_cli(args, manager)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
