# Design Specification: Multi-Provider AI Chat History Manager

- **Author**: Antigravity Assistant & Son
- **Date**: 2026-09-26
- **Status**: Draft
- **Target Location**: `/Users/son/Workspaces/dotfiles/scripts/AI/manage-chat-history`

---

## 1. Overview & Goals

Developers using multiple AI CLI tools (such as Google Antigravity CLI `agy`, Anthropic Claude Code, and OpenAI Codex) frequently accumulate chat sessions across dozens of workspace directories. Managing these sessions (listing, searching, inspecting, resuming, and deleting obsolete chats) currently requires manual database edits, directory navigation, or memorizing CLI session flags.

This project delivers a lightweight, unified, and cross-platform **AI Chat History Manager** that:
1. **Interactive Terminal UI (TUI)**: Offers an intuitive, responsive terminal interface driven entirely by keyboard shortcuts (arrow navigation, multi-select checkboxes, live preview panel, search filter, and instant resume/delete actions).
2. **Scriptable CLI**: Supports standard subcommands (`list`, `show`, `resume`, `delete`) with JSON and plain-text output formats.
3. **Cross-Platform & Zero Dependencies**: Built strictly using the **Python Standard Library** (Python 3.8+), requiring zero third-party `pip` packages. Runs out-of-the-box on macOS, Linux, and Windows (PowerShell, CMD, Windows Terminal).
4. **Extensible Provider Architecture**: Primary out-of-the-box support for **Google Antigravity CLI (`agy`)**, with a clean pluggable interface for **Claude Code** and **Codex**.

---

## 2. Architecture & Directory Layout

### 2.1 Provider Pattern Architecture

```
                    ┌──────────────────────────────────────────────┐
                    │               manage_chat.py                 │
                    │         (CLI Entrypoint & Dispatch)          │
                    └──────────────┬───────────────────────────────┘
                                   │
                ┌──────────────────┴──────────────────┐
                ▼                                     ▼
     ┌──────────────────────┐              ┌──────────────────────┐
     │  Interactive TUI     │              │  Subcommands Engine  │
     │  (Terminal UI Loop)  │              │ (list, show, resume) │
     └──────────┬───────────┘              └──────────┬───────────┘
                │                                     │
                └──────────────────┬──────────────────┘
                                   ▼
                    ┌──────────────────────────────┐
                    │        SessionManager        │
                    │  (Filter, Search, Registry)  │
                    └──────────────┬───────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          ▼                        ▼                        ▼
 ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
 │   Antigravity   │      │   Claude Code   │      │      Codex      │
 │    Provider     │      │ Provider (Stub) │      │ Provider (Stub) │
 └─────────────────┘      └─────────────────┘      └─────────────────┘
```

### 2.2 Directory Structure

```
/Users/son/Workspaces/dotfiles/scripts/AI/manage-chat-history/
├── manage_chat.py                # Main executable entrypoint (#!/usr/bin/env python3)
├── README.md                     # Documentation and usage guide
├── core/
│   ├── __init__.py
│   ├── models.py                 # Data models (Session, SessionDetails, DeleteResult)
│   ├── provider_base.py          # Abstract Base Class BaseProvider
│   ├── platform_utils.py         # Cross-platform raw input, ANSI styling, paths, subprocess
│   ├── manager.py                # SessionManager (aggregates providers, handles filters/sorts)
│   ├── tui.py                    # Terminal UI implementation (draw loop, event loop, shortcuts)
│   └── cli.py                    # Non-interactive CLI parser (argparse subcommands)
├── providers/
│   ├── __init__.py
│   ├── antigravity.py            # Complete Antigravity CLI (agy) provider implementation
│   ├── claude.py                 # Claude Code provider stub & schema
│   └── codex.py                  # OpenAI Codex provider stub & schema
└── tests/
    ├── __init__.py
    ├── test_platform_utils.py    # Tests for URI decoding, cross-platform paths
    ├── test_antigravity.py       # Unit tests for Antigravity SQLite reading, filtering, deletion
    └── test_manager.py           # Unit tests for SessionManager
```

---

## 3. Data Models & Core Contracts

### 3.1 Data Models (`core/models.py`)

```python
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional

@dataclass
class Session:
    id: str
    provider: str               # 'agy', 'claude', 'codex'
    provider_display: str       # 'Antigravity (agy)', 'Claude Code', etc.
    title: str
    preview: str
    workspace_paths: List[Path]
    last_modified: datetime
    step_count: int = 0
    status: str = ""
    is_active: bool = False     # Session currently running / locked

@dataclass
class SessionDetails:
    session: Session
    messages_snippet: List[str] = field(default_factory=list)
    raw_metadata: dict = field(default_factory=dict)

@dataclass
class DeleteResult:
    provider: str
    succeeded_ids: List[str]
    failed_ids: List[str]
    error_messages: List[str]
```

### 3.2 Provider Abstract Base Class (`core/provider_base.py`)

```python
from abc import ABC, abstractmethod
from pathlib import Path
from typing import List, Optional
from core.models import Session, SessionDetails, DeleteResult

class BaseProvider(ABC):
    @property
    @abstractmethod
    def name(self) -> str:
        """Unique provider code (e.g. 'agy', 'claude', 'codex')"""
        pass

    @property
    @abstractmethod
    def display_name(self) -> str:
        """Human-readable provider name (e.g. 'Antigravity CLI')"""
        pass

    @abstractmethod
    def is_available(self) -> bool:
        """Check if CLI tool or data directory exists on this system"""
        pass

    @abstractmethod
    def list_sessions(self, cwd_only: bool = False, current_dir: Optional[Path] = None) -> List[Session]:
        """Fetch all sessions sorted by last modified descending"""
        pass

    @abstractmethod
    def get_session_details(self, session_id: str) -> Optional[SessionDetails]:
        """Retrieve full details and recent messages snippet for preview"""
        pass

    @abstractmethod
    def resume_session(self, session: Session) -> None:
        """Spawn the AI CLI process resuming the given session in its workspace"""
        pass

    @abstractmethod
    def delete_sessions(self, session_ids: List[str]) -> DeleteResult:
        """Safely delete session databases, logs, and artifacts"""
        pass
```

---

## 4. Antigravity Provider Implementation Details (`providers/antigravity.py`)

### 4.1 Storage Layout
- **Root Directory**:
  - macOS / Linux: `~/.gemini/antigravity-cli/`
  - Windows: `%USERPROFILE%\.gemini\antigravity-cli\`
- **Database**: `conversation_summaries.db`
  - Table `conversation_summaries`
  - Key columns: `conversation_id`, `title`, `preview`, `step_count`, `last_modified_time`, `workspace_uris`, `status`
- **Session Data**: `conversations/<conversation_id>.db` (+ optional `.db-shm`, `.db-wal`)
- **Artifacts**: `brain/<conversation_id>/`
- **Locks & Annotations**: `presence/<conversation_id>.lock`, `annotations/<conversation_id>.pbtxt`

### 4.2 Workspace URI Decoding
Stored in SQLite as JSON array of URIs (e.g., `["file:///Users/son/Workspaces/foo"]` or on Windows `["file:///C:/Workspaces/foo"]`).
- Decoded using `urllib.parse.urlparse` and `urllib.request.url2pathname` to ensure cross-platform compliance (correctly handling Windows drive letters and spaces).

### 4.3 Safe Deletion Procedure
When `delete_sessions(session_ids)` is invoked:
1. **Active Check**: Check for existing `presence/<id>.lock`. If locked, flag a warning.
2. **SQLite Cleanup**:
   ```sql
   DELETE FROM conversation_summaries WHERE conversation_id IN (?);
   ```
3. **Filesystem Cleanup**:
   - Remove `conversations/<id>.db*`
   - Remove directory tree `brain/<id>/` recursively
   - Remove `annotations/<id>.pbtxt` and `presence/<id>.lock`
4. **Result Reporting**: Return `DeleteResult` recording deleted sessions and any I/O errors.

### 4.4 Resume Execution
1. Find executable `agy` via `shutil.which("agy")`.
2. Extract the primary workspace path from `session.workspace_paths`. If directory exists, set as `cwd`; otherwise default to current working directory with a warning.
3. Temporarily exit TUI alternate screen buffer, restore normal terminal raw mode, and call:
   ```python
   subprocess.run(["agy", "--conversation", session.id], cwd=target_dir)
   ```
4. Upon exit of `agy`, restore TUI alternate screen buffer and reload session list.

---

## 5. Cross-Platform Terminal UI (`core/tui.py` & `core/platform_utils.py`)

### 5.1 Terminal Control & Input Handling
- **Unix (macOS, Linux)**: Uses `termios` and `tty.setraw(sys.stdin.fileno())` to read single characters and ANSI escape sequences (arrows, function keys).
- **Windows**: Uses standard library `msvcrt.getch()` and `msvcrt.kbhit()`.
- **ANSI Terminal Enablement**: On Windows 10/11, enable virtual terminal processing via `ctypes.windll.kernel32.SetConsoleMode`.
- **Clean Terminal Exit**: Wrap main loop in `try...finally:` to ensure `\033[?1049l` (exit alternate screen) and `\033[?25h` (show cursor) are always executed even on unhandled exceptions or `SIGINT`.

### 5.2 Keybindings Specification

| Key | Action | Description |
| :--- | :--- | :--- |
| `↑` / `k` | Move Up | Move cursor to previous session |
| `↓` / `j` | Move Down | Move cursor to next session |
| `PageUp` / `PageDown` | Page Scroll | Scroll list by visible page height |
| `Home` / `End` | Jump | Jump to top / bottom of list |
| `Space` | Toggle Select | Toggle `[x]` checkbox on current session for batch actions |
| `a` | Select All | Select or deselect all currently visible sessions |
| `Enter` | Resume Session | Launch CLI into selected session in its workspace |
| `d` or `x` | Delete | Delete selected session(s) with confirmation dialog `[y/N]` |
| `/` | Search / Filter | Open search bar to filter by title or workspace path |
| `w` | Filter Workspace | Toggle: Filter to current directory vs show all workspaces |
| `p` or `Tab` | Switch Provider | Cycle filter: `[ALL]` ➔ `[Antigravity]` ➔ `[Claude Code]` ➔ `[Codex]` |
| `r` | Refresh | Re-query databases for newly created or modified sessions |
| `?` | Help | Display modal showing all available keybindings |
| `q` or `Esc` | Quit | Exit TUI and return to shell prompt |

### 5.3 UI Layout Diagram

```
┌─ [AI Chat History Manager] ── Provider: [ALL] ── Scope: [ALL] ──────────────────────────────────────┐
│ Search (/): [ web                                                                     ] 12 results │
├──────────────────────────────────────────────────────┬──────────────────────────────────────────────┤
│  #   ID / Title                     Modified         │ Session Details:                             │
│ ───────────────────────────────────────────────────  │ -------------------------------------------- │
│>[x]  Web Assignment Question 1      26/09 09:34 (agy)│ ID: 38461cb4-b507-47c4-a863-7289230db7c0     │
│ [ ]  Setup Dự Án JSP Servlet        25/09 04:22 (agy)│ Provider: Antigravity (agy)                 │
│                                                      │ Workspace: ~/Workspaces/bt_lap_trinh_web     │
│                                                      │ Updated: 2026-09-26 09:34:16 (8 steps)       │
│                                                      │ Status: idle                                 │
│                                                      │ -------------------------------------------- │
│                                                      │ Preview:                                     │
│                                                      │ > user: Phân tích bài tập 1 lập trình web    │
│                                                      │ > model: Tôi đã xem file mô tả bài tập...    │
├──────────────────────────────────────────────────────┴──────────────────────────────────────────────┤
│ [Enter] Resume  [Space] Select  [d] Delete (1 selected)  [w] Filter CWD  [p] Provider  [q] Quit     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Non-Interactive CLI Interface (`core/cli.py`)

The tool supports standard scriptable CLI flags:

- `manage_chat.py list [--provider agy|claude|codex] [--cwd] [--json] [--limit N]`
  - Prints session table or machine-readable JSON array.
- `manage_chat.py show <session_id> [--provider agy]`
  - Prints session metadata and transcript snippet.
- `manage_chat.py resume <session_id> [--provider agy]`
  - Resumes session directly from command line.
- `manage_chat.py delete <session_id...> [--provider agy] [-y/--yes]`
  - Deletes one or more sessions. Prompts for confirmation unless `-y` is supplied.

---

## 7. Extensibility for Claude Code & Codex

### 7.1 Claude Code Adapter (`providers/claude.py`)
- Standard detection: Check existence of `~/.claude` or `claude` executable via `shutil.which`.
- Session discovery: Scans project history in `~/.claude/projects/` or `~/.claude.json`.
- Resume command: `claude resume <session_id>` or `claude --resume <session_id>`.
- Deletion: Deletes JSON transcript file and prunes index.

### 7.2 OpenAI Codex Adapter (`providers/codex.py`)
- Standard detection: Check `codex` executable and log directory.
- Pre-configured adapter hooks ready for local transcript logs.

---

## 8. Verification & Testing Strategy

1. **Unit Tests (`tests/test_platform_utils.py`)**:
   - Verify URI to filesystem path conversion for POSIX and Windows formats.
   - Verify terminal control sequences and string truncation utilities.
2. **Unit Tests (`tests/test_antigravity.py`)**:
   - Mock SQLite `conversation_summaries.db` in `tempfile.TemporaryDirectory`.
   - Test session listing, ordering, and field parsing.
   - Test safe deletion: assert DB record is removed, session DB file is unlinked, brain directory is recursively deleted.
   - Test error resiliency: simulate missing files or read-only directories.
3. **Integration Test on Live System**:
   - Execute read-only `manage_chat.py list` against real `~/.gemini/antigravity-cli/` data and verify output matches SQLite data.
   - Verify interactive TUI rendering, search filtering, and clean exit.
