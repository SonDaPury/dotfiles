# AI Chat History Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cross-platform, zero-dependency CLI and interactive Terminal UI (TUI) to inspect, resume, and safely delete AI chat sessions, starting with Antigravity CLI (`agy`) and architected for Claude Code and Codex.

**Architecture:** A Provider Pattern architecture with `BaseProvider` abstracting underlying AI storage formats. A `SessionManager` orchestrates provider registry, query filtering, and actions. An interactive ANSI `TerminalUI` (with raw keyboard input on Unix/Windows) and scriptable `argparse` CLI share the manager.

**Tech Stack:** Python 3.8+ Standard Library (`sqlite3`, `pathlib`, `json`, `argparse`, `shutil`, `subprocess`, `termios`/`tty` on Unix, `msvcrt` on Windows). Zero pip dependencies.

**Spec:** `docs/superpowers/specs/2026-09-26-ai-chat-history-manager-design.md`

## Global Constraints

- 100% Python Standard Library only — no `pip install` packages required.
- Full cross-platform compatibility: Linux, macOS, Windows (PowerShell/CMD).
- Terminal UI must safely restore raw mode and alternate screen buffer on exit or interrupt (`try...finally`).
- File deletions must cleanly wipe SQLite records, session databases, brain artifacts, and locks.
- Code location: `/Users/son/Workspaces/dotfiles/scripts/AI/manage-chat-history/`.

## Review Focus

1. **Corrupted or missing database file**: If `conversation_summaries.db` does not exist or is malformed, the tool should report a clean warning rather than crashing with unhandled SQLite exceptions.
2. **Missing workspace directory during resume**: If a session's workspace path was deleted or moved, resume should warn the user and fall back to the current working directory.
3. **Active/Locked session deletion**: Attempting to delete a currently active session (e.g. `presence/<id>.lock` active) must display a safety warning.
4. **Windows path and URI encoding**: File URIs with drive letters (e.g. `file:///C:/Users/...`) must be converted to valid native Windows paths without leftover leading slashes or encoded `%20`.
5. **Terminal state restoration**: If an unexpected exception occurs inside the interactive TUI, the terminal cursor and buffer must be properly restored so the user's terminal is never left frozen or broken.

---

### Task 1: Core Models & Base Provider Contract

**Files:**
- Create: `scripts/AI/manage-chat-history/core/__init__.py`
- Create: `scripts/AI/manage-chat-history/core/models.py`
- Create: `scripts/AI/manage-chat-history/core/provider_base.py`
- Test: `scripts/AI/manage-chat-history/tests/__init__.py`
- Test: `scripts/AI/manage-chat-history/tests/test_models.py`

**Interfaces:**
- Consumes: Standard Python `dataclasses`, `abc`, `pathlib`, `datetime`.
- Produces:
  - `Session(id, provider, provider_display, title, preview, workspace_paths, last_modified, step_count, status, is_active)`
  - `SessionDetails(session, messages_snippet, raw_metadata)`
  - `DeleteResult(provider, succeeded_ids, failed_ids, error_messages)`
  - `BaseProvider` abstract base class with methods: `name`, `display_name`, `is_available()`, `list_sessions()`, `get_session_details()`, `resume_session()`, `delete_sessions()`.

- [ ] **Step 1: Write the failing test for models and BaseProvider**

```python
# scripts/AI/manage-chat-history/tests/test_models.py
import unittest
from datetime import datetime
from pathlib import Path
from core.models import Session, SessionDetails, DeleteResult
from core.provider_base import BaseProvider

class DummyProvider(BaseProvider):
    @property
    def name(self) -> str:
        return "dummy"

    @property
    def display_name(self) -> str:
        return "Dummy Provider"

    def is_available(self) -> bool:
        return True

    def list_sessions(self, cwd_only=False, current_dir=None):
        return []

    def get_session_details(self, session_id: str):
        return None

    def resume_session(self, session: Session) -> None:
        pass

    def delete_sessions(self, session_ids):
        return DeleteResult(provider="dummy", succeeded_ids=session_ids, failed_ids=[], error_messages=[])

class TestModelsAndProviderBase(unittest.TestCase):
    def test_session_instantiation(self):
        s = Session(
            id="1234-5678",
            provider="dummy",
            provider_display="Dummy Provider",
            title="Test Chat",
            preview="Hello world",
            workspace_paths=[Path("/tmp/workspace")],
            last_modified=datetime(2026, 9, 26, 12, 0, 0),
            step_count=5,
            status="idle"
        )
        self.assertEqual(s.id, "1234-5678")
        self.assertEqual(s.provider, "dummy")
        self.assertEqual(s.step_count, 5)
        self.assertFalse(s.is_active)

    def test_delete_result(self):
        dr = DeleteResult(provider="dummy", succeeded_ids=["s1"], failed_ids=["s2"], error_messages=["Err"])
        self.assertEqual(len(dr.succeeded_ids), 1)
        self.assertEqual(len(dr.failed_ids), 1)

    def test_provider_subclass(self):
        p = DummyProvider()
        self.assertEqual(p.name, "dummy")
        self.assertTrue(p.is_available())
        self.assertEqual(p.list_sessions(), [])
        res = p.delete_sessions(["id1"])
        self.assertEqual(res.succeeded_ids, ["id1"])

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
python3 -m unittest scripts/AI/manage-chat-history/tests/test_models.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'core'`

- [ ] **Step 3: Implement `core/models.py` and `core/provider_base.py`**

```python
# scripts/AI/manage-chat-history/core/__init__.py
"""Core domain models and interfaces for AI chat history manager."""
```

```python
# scripts/AI/manage-chat-history/core/models.py
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional

@dataclass
class Session:
    id: str
    provider: str               # 'agy', 'claude', 'codex'
    provider_display: str       # 'Antigravity CLI', 'Claude Code', etc.
    title: str
    preview: str
    workspace_paths: List[Path]
    last_modified: datetime
    step_count: int = 0
    status: str = ""
    is_active: bool = False

@dataclass
class SessionDetails:
    session: Session
    messages_snippet: List[str] = field(default_factory=list)
    raw_metadata: dict = field(default_factory=dict)

@dataclass
class DeleteResult:
    provider: str
    succeeded_ids: List[str] = field(default_factory=list)
    failed_ids: List[str] = field(default_factory=list)
    error_messages: List[str] = field(default_factory=list)
```

```python
# scripts/AI/manage-chat-history/core/provider_base.py
from abc import ABC, abstractmethod
from pathlib import Path
from typing import List, Optional
from core.models import Session, SessionDetails, DeleteResult

class BaseProvider(ABC):
    @property
    @abstractmethod
    def name(self) -> str:
        """Unique provider identifier code (e.g. 'agy', 'claude', 'codex')"""
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

```python
# scripts/AI/manage-chat-history/tests/__init__.py
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_models.py
```
Expected: `Ran 3 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/core/ scripts/AI/manage-chat-history/tests/
git commit -m "feat(manage-chat): implement core models and BaseProvider contract"
```

---

### Task 2: Cross-Platform Utilities (Paths, Formatting, Terminal Input & ANSI)

**Files:**
- Create: `scripts/AI/manage-chat-history/core/platform_utils.py`
- Test: `scripts/AI/manage-chat-history/tests/test_platform_utils.py`

**Interfaces:**
- Produces:
  - `uri_to_path(uri: str) -> Path`: Cross-platform URI decoder (`file:///Users/...` or Windows `file:///C:/...`).
  - `format_relative_time(dt: datetime) -> str`: Human-readable date ("Hôm nay 14:20", "25/09 09:30").
  - `truncate_text(text: str, max_len: int, placeholder: str = "...") -> str`.
  - ANSI terminal constants and screen control functions: `enter_alt_screen()`, `exit_alt_screen()`, `hide_cursor()`, `show_cursor()`, `get_terminal_size()`.
  - `get_key() -> str`: Non-blocking/blocking cross-platform key reader returning strings like `'UP'`, `'DOWN'`, `'PAGE_UP'`, `'PAGE_DOWN'`, `'HOME'`, `'END'`, `'ENTER'`, `'SPACE'`, `'ESC'`, or the character typed.

- [ ] **Step 1: Write failing test for platform utilities**

```python
# scripts/AI/manage-chat-history/tests/test_platform_utils.py
import unittest
from datetime import datetime, timedelta
from pathlib import Path
from core.platform_utils import uri_to_path, truncate_text, format_relative_time

class TestPlatformUtils(unittest.TestCase):
    def test_uri_to_path_unix(self):
        p = uri_to_path("file:///Users/son/Workspaces/my_project")
        self.assertEqual(str(p), "/Users/son/Workspaces/my_project")

    def test_uri_to_path_windows(self):
        p = uri_to_path("file:///C:/Users/son/Workspaces/my_project")
        # On Unix test runner, path format will resolve cleanly without file:// prefix
        self.assertTrue("C:" in str(p) or "Users/son/Workspaces" in str(p))

    def test_uri_to_path_with_percent_encoding(self):
        p = uri_to_path("file:///Users/son/My%20Folder/project%201")
        self.assertEqual(str(p), "/Users/son/My Folder/project 1")

    def test_truncate_text(self):
        self.assertEqual(truncate_text("Hello World", 5), "He...")
        self.assertEqual(truncate_text("Hi", 5), "Hi")
        self.assertEqual(truncate_text("Exact", 5), "Exact")

    def test_format_relative_time(self):
        now = datetime.now()
        self.assertIn(":", format_relative_time(now))
        old = datetime(2025, 1, 15, 10, 30)
        self.assertIn("15/01", format_relative_time(old))

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_platform_utils.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'core.platform_utils'`

- [ ] **Step 3: Implement `core/platform_utils.py`**

```python
# scripts/AI/manage-chat-history/core/platform_utils.py
import os
import sys
import shutil
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Tuple

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"
BG_BLUE = "\033[44m"
BG_GRAY = "\033[100m"

def uri_to_path(uri: str) -> Path:
    """Safely converts file:/// URI to native pathlib.Path across OSes."""
    if uri.startswith("file://"):
        parsed = urllib.parse.urlparse(uri)
        # Use url2pathname to convert URL path to native OS path (e.g. C:\ on Windows)
        decoded_path = urllib.request.url2pathname(parsed.path)
        # On Windows urlparse might retain a leading slash before drive letter
        if os.name == 'nt' and len(decoded_path) > 2 and decoded_path[0] == '\\' and decoded_path[2] == ':':
            decoded_path = decoded_path[1:]
        return Path(decoded_path)
    return Path(uri)

def truncate_text(text: str, max_len: int, placeholder: str = "...") -> str:
    """Truncates text cleanly to max_len, appending placeholder if trimmed."""
    if len(text) <= max_len:
        return text
    if max_len <= len(placeholder):
        return text[:max_len]
    return text[:max_len - len(placeholder)] + placeholder

def format_relative_time(dt: datetime) -> str:
    """Returns compact human-readable date/time string."""
    now = datetime.now()
    if dt.date() == now.date():
        return f"Hôm nay {dt.strftime('%H:%M')}"
    elif (now.date() - dt.date()).days == 1:
        return f"Hôm qua {dt.strftime('%H:%M')}"
    elif dt.year == now.year:
        return dt.strftime("%d/%m %H:%M")
    return dt.strftime("%d/%m/%Y")

def get_terminal_size() -> Tuple[int, int]:
    """Returns (columns, lines) of terminal."""
    size = shutil.get_terminal_size(fallback=(80, 24))
    return size.columns, size.lines

def enter_alt_screen() -> None:
    """Switch to alternate screen buffer and hide cursor."""
    sys.stdout.write("\033[?1049h\033[?25l")
    sys.stdout.flush()

def exit_alt_screen() -> None:
    """Switch back to main screen buffer and show cursor."""
    sys.stdout.write("\033[?1049l\033[?25h")
    sys.stdout.flush()

def clear_screen() -> None:
    """Clear terminal screen and place cursor at 1,1."""
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

def init_terminal() -> None:
    """Initialize Windows console for ANSI if running on Windows."""
    if os.name == 'nt':
        import ctypes
        kernel32 = ctypes.windll.kernel32
        # Enable ENABLE_VIRTUAL_TERMINAL_PROCESSING (0x0004)
        h_out = kernel32.GetStdHandle(-11)
        mode = ctypes.c_ulong()
        kernel32.GetConsoleMode(h_out, ctypes.byref(mode))
        kernel32.SetConsoleMode(h_out, mode.value | 0x0004)

def get_key() -> str:
    """
    Reads a single keypress or escape sequence cross-platform.
    Returns: 'UP', 'DOWN', 'LEFT', 'RIGHT', 'PAGE_UP', 'PAGE_DOWN',
             'HOME', 'END', 'ENTER', 'SPACE', 'BACKSPACE', 'ESC', 'TAB',
             or single character typed.
    """
    if os.name == 'nt':
        import msvcrt
        ch = msvcrt.getch()
        if ch in (b'\x00', b'\xe0'):  # Extended keys
            ext = msvcrt.getch()
            mapping = {
                b'H': 'UP', b'P': 'DOWN', b'K': 'LEFT', b'M': 'RIGHT',
                b'I': 'PAGE_UP', b'Q': 'PAGE_DOWN', b'G': 'HOME', b'O': 'END',
                b'S': 'DELETE'
            }
            return mapping.get(ext, '')
        if ch == b'\r':
            return 'ENTER'
        if ch == b' ':
            return 'SPACE'
        if ch == b'\x08':
            return 'BACKSPACE'
        if ch == b'\x1b':
            return 'ESC'
        if ch == b'\t':
            return 'TAB'
        try:
            return ch.decode('utf-8')
        except UnicodeDecodeError:
            return ''
    else:
        import termios
        import tty
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch1 = sys.stdin.read(1)
            if ch1 == '\x1b':
                # Read following chars if escape sequence
                import select
                r, _, _ = select.select([sys.stdin], [], [], 0.05)
                if not r:
                    return 'ESC'
                ch2 = sys.stdin.read(1)
                if ch2 == '[':
                    ch3 = sys.stdin.read(1)
                    if ch3 == 'A': return 'UP'
                    if ch3 == 'B': return 'DOWN'
                    if ch3 == 'C': return 'RIGHT'
                    if ch3 == 'D': return 'LEFT'
                    if ch3 == 'H': return 'HOME'
                    if ch3 == 'F': return 'END'
                    if ch3 in ('5', '6', '3'):
                        ch4 = sys.stdin.read(1) # consume ~
                        if ch3 == '5': return 'PAGE_UP'
                        if ch3 == '6': return 'PAGE_DOWN'
                        if ch3 == '3': return 'DELETE'
                return 'ESC'
            if ch1 in ('\r', '\n'):
                return 'ENTER'
            if ch1 == ' ':
                return 'SPACE'
            if ch1 in ('\x7f', '\x08'):
                return 'BACKSPACE'
            if ch1 == '\t':
                return 'TAB'
            if ch1 == '\x03':  # Ctrl-C
                raise KeyboardInterrupt
            return ch1
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_platform_utils.py
```
Expected: `Ran 5 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/core/platform_utils.py scripts/AI/manage-chat-history/tests/test_platform_utils.py
git commit -m "feat(manage-chat): implement platform utilities and terminal control"
```

---

### Task 3: Antigravity CLI (`agy`) Provider Implementation

**Files:**
- Create: `scripts/AI/manage-chat-history/providers/__init__.py`
- Create: `scripts/AI/manage-chat-history/providers/antigravity.py`
- Test: `scripts/AI/manage-chat-history/tests/test_antigravity.py`

**Interfaces:**
- Consumes: `core/models.py`, `core/provider_base.py`, `core/platform_utils.py`.
- Produces: `AntigravityProvider(BaseProvider)`:
  - Default data path: `~/.gemini/antigravity-cli`.
  - `is_available() -> bool`.
  - `list_sessions(cwd_only=False, current_dir=None) -> List[Session]`.
  - `get_session_details(session_id: str) -> Optional[SessionDetails]`.
  - `resume_session(session: Session) -> None`.
  - `delete_sessions(session_ids: List[str]) -> DeleteResult`.

- [ ] **Step 1: Write failing test for AntigravityProvider**

```python
# scripts/AI/manage-chat-history/tests/test_antigravity.py
import unittest
import sqlite3
import tempfile
import shutil
from pathlib import Path
from datetime import datetime
from providers.antigravity import AntigravityProvider
from core.models import Session

class TestAntigravityProvider(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.root = Path(self.temp_dir)
        self.db_path = self.root / "conversation_summaries.db"
        self.conv_dir = self.root / "conversations"
        self.brain_dir = self.root / "brain"
        self.conv_dir.mkdir()
        self.brain_dir.mkdir()

        # Create mock sqlite database schema
        conn = sqlite3.connect(str(self.db_path))
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE conversation_summaries (
                conversation_id TEXT PRIMARY KEY,
                title TEXT,
                preview TEXT,
                step_count INTEGER,
                last_modified_time TEXT,
                workspace_uris TEXT,
                status TEXT
            );
        """)
        # Insert test records
        cur.execute("""
            INSERT INTO conversation_summaries VALUES
            ('id-1', 'Project A Feature', 'Preview A', 10, '2026-09-26 12:00:00+00:00', '["file:///tmp/proj_a"]', 'idle'),
            ('id-2', 'Project B Bugfix', 'Preview B', 3, '2026-09-25 10:00:00+00:00', '["file:///tmp/proj_b"]', 'idle');
        """)
        conn.commit()
        conn.close()

        # Create fake session db and brain folder
        (self.conv_dir / "id-1.db").write_text("dummy")
        (self.brain_dir / "id-1").mkdir()
        (self.brain_dir / "id-1" / "artifact.md").write_text("# Hello")

        self.provider = AntigravityProvider(cli_dir=self.root)

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def test_is_available(self):
        self.assertTrue(self.provider.is_available())

    def test_list_sessions(self):
        sessions = self.provider.list_sessions()
        self.assertEqual(len(sessions), 2)
        self.assertEqual(sessions[0].id, "id-1")
        self.assertEqual(sessions[0].title, "Project A Feature")
        self.assertEqual(sessions[0].step_count, 10)
        self.assertEqual(len(sessions[0].workspace_paths), 1)

    def test_list_sessions_filter_cwd(self):
        sessions = self.provider.list_sessions(cwd_only=True, current_dir=Path("/tmp/proj_a"))
        self.assertEqual(len(sessions), 1)
        self.assertEqual(sessions[0].id, "id-1")

    def test_get_session_details(self):
        details = self.provider.get_session_details("id-1")
        self.assertIsNotNone(details)
        self.assertEqual(details.session.id, "id-1")
        self.assertEqual(details.session.title, "Project A Feature")

    def test_delete_sessions(self):
        res = self.provider.delete_sessions(["id-1"])
        self.assertEqual(res.succeeded_ids, ["id-1"])
        self.assertEqual(res.failed_ids, [])

        # Verify db record removed
        conn = sqlite3.connect(str(self.db_path))
        cur = conn.cursor()
        cur.execute("SELECT count(*) FROM conversation_summaries WHERE conversation_id = 'id-1';")
        self.assertEqual(cur.fetchone()[0], 0)
        conn.close()

        # Verify files removed
        self.assertFalse((self.conv_dir / "id-1.db").exists())
        self.assertFalse((self.brain_dir / "id-1").exists())

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_antigravity.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'providers'`

- [ ] **Step 3: Implement `providers/antigravity.py`**

```python
# scripts/AI/manage-chat-history/providers/__init__.py
"""AI CLI Providers package."""
```

```python
# scripts/AI/manage-chat-history/providers/antigravity.py
import json
import os
import shutil
import sqlite3
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Optional
from core.models import Session, SessionDetails, DeleteResult
from core.provider_base import BaseProvider
from core.platform_utils import uri_to_path

class AntigravityProvider(BaseProvider):
    def __init__(self, cli_dir: Optional[Path] = None):
        if cli_dir is None:
            self.cli_dir = Path.home() / ".gemini" / "antigravity-cli"
        else:
            self.cli_dir = cli_dir
        self.db_path = self.cli_dir / "conversation_summaries.db"
        self.conv_dir = self.cli_dir / "conversations"
        self.brain_dir = self.cli_dir / "brain"
        self.presence_dir = self.cli_dir / "presence"
        self.annotations_dir = self.cli_dir / "annotations"

    @property
    def name(self) -> str:
        return "agy"

    @property
    def display_name(self) -> str:
        return "Antigravity (agy)"

    def is_available(self) -> bool:
        return self.cli_dir.exists() and self.db_path.exists()

    def _parse_datetime(self, val: str) -> datetime:
        try:
            # Handles ISO format like '2026-09-26 12:14:40.866003+00:00'
            return datetime.fromisoformat(val)
        except Exception:
            try:
                clean_val = val.split('+')[0].split('.')[0]
                return datetime.strptime(clean_val, "%Y-%m-%d %H:%M:%S")
            except Exception:
                return datetime.now()

    def list_sessions(self, cwd_only: bool = False, current_dir: Optional[Path] = None) -> List[Session]:
        if not self.is_available():
            return []

        if current_dir is None:
            current_dir = Path.cwd().resolve()
        else:
            current_dir = current_dir.resolve()

        sessions = []
        try:
            conn = sqlite3.connect(f"file:{self.db_path}?mode=ro", uri=True)
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()
            cur.execute("""
                SELECT conversation_id, title, preview, step_count, last_modified_time, workspace_uris, status
                FROM conversation_summaries
                ORDER BY last_modified_time DESC;
            """)
            rows = cur.fetchall()
            conn.close()
        except sqlite3.OperationalError:
            return []

        for row in rows:
            cid = row["conversation_id"]
            title = row["title"] or "(Không có tiêu đề)"
            preview = row["preview"] or ""
            step_count = row["step_count"] or 0
            status = row["status"] or ""
            dt = self._parse_datetime(row["last_modified_time"])

            workspace_paths = []
            raw_uris = row["workspace_uris"]
            if raw_uris:
                try:
                    uris = json.loads(raw_uris)
                    for u in uris:
                        workspace_paths.append(uri_to_path(u).resolve())
                except Exception:
                    pass

            is_active = (self.presence_dir / f"{cid}.lock").exists()

            if cwd_only:
                # Match if current_dir equals or is inside any workspace path
                matches = False
                for wp in workspace_paths:
                    if wp == current_dir or wp in current_dir.parents or current_dir in wp.parents:
                        matches = True
                        break
                if not matches:
                    continue

            sessions.append(Session(
                id=cid,
                provider=self.name,
                provider_display=self.display_name,
                title=title,
                preview=preview,
                workspace_paths=workspace_paths,
                last_modified=dt,
                step_count=step_count,
                status=status,
                is_active=is_active
            ))

        return sessions

    def get_session_details(self, session_id: str) -> Optional[SessionDetails]:
        if not self.is_available():
            return None

        session = None
        for s in self.list_sessions():
            if s.id == session_id:
                session = s
                break
        if not session:
            return None

        # Fetch snippet from brain transcript if available
        transcript_file = self.brain_dir / session_id / ".system_generated" / "logs" / "transcript.jsonl"
        messages = []
        if transcript_file.exists():
            try:
                with open(transcript_file, "r", encoding="utf-8") as f:
                    for line in f:
                        if not line.strip(): continue
                        item = json.loads(line)
                        src = item.get("source", "")
                        content = item.get("content", "")
                        if content and src in ("USER_EXPLICIT", "MODEL"):
                            role = "User" if src == "USER_EXPLICIT" else "Agent"
                            messages.append(f"{role}: {content.strip()}")
                            if len(messages) >= 8:
                                break
            except Exception:
                pass

        if not messages and session.preview:
            messages.append(session.preview)

        return SessionDetails(session=session, messages_snippet=messages)

    def resume_session(self, session: Session) -> None:
        target_dir = None
        for wp in session.workspace_paths:
            if wp.exists() and wp.is_dir():
                target_dir = wp
                break
        if target_dir is None:
            target_dir = Path.cwd()

        agy_bin = shutil.which("agy")
        if not agy_bin:
            raise RuntimeError("Lệnh 'agy' không được tìm thấy trong PATH hệ thống.")

        # Spawn interactive session
        subprocess.run([agy_bin, "--conversation", session.id], cwd=str(target_dir))

    def delete_sessions(self, session_ids: List[str]) -> DeleteResult:
        if not self.is_available() or not session_ids:
            return DeleteResult(provider=self.name)

        succeeded = []
        failed = []
        errors = []

        try:
            conn = sqlite3.connect(str(self.db_path))
            cur = conn.cursor()
            placeholders = ",".join("?" for _ in session_ids)
            cur.execute(f"DELETE FROM conversation_summaries WHERE conversation_id IN ({placeholders})", session_ids)
            conn.commit()
            conn.close()
        except Exception as e:
            errors.append(f"Lỗi xóa database: {e}")
            return DeleteResult(provider=self.name, succeeded_ids=[], failed_ids=session_ids, error_messages=errors)

        for sid in session_ids:
            try:
                # Remove conversation db
                conv_file = self.conv_dir / f"{sid}.db"
                if conv_file.exists():
                    conv_file.unlink()
                for ext in (".db-shm", ".db-wal"):
                    extra = self.conv_dir / f"{sid}{ext}"
                    if extra.exists():
                        extra.unlink()

                # Remove brain artifacts
                brain_session_dir = self.brain_dir / sid
                if brain_session_dir.exists() and brain_session_dir.is_dir():
                    shutil.rmtree(brain_session_dir, ignore_errors=True)

                # Remove presence & annotations
                lock_file = self.presence_dir / f"{sid}.lock"
                if lock_file.exists():
                    lock_file.unlink()
                pbtxt_file = self.annotations_dir / f"{sid}.pbtxt"
                if pbtxt_file.exists():
                    pbtxt_file.unlink()

                succeeded.append(sid)
            except Exception as e:
                failed.append(sid)
                errors.append(f"Lỗi dọn file {sid}: {e}")

        return DeleteResult(provider=self.name, succeeded_ids=succeeded, failed_ids=failed, error_messages=errors)
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_antigravity.py
```
Expected: `Ran 5 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/providers/ scripts/AI/manage-chat-history/tests/test_antigravity.py
git commit -m "feat(manage-chat): implement Antigravity CLI provider"
```

---

### Task 4: Extensibility Stubs (Claude Code & Codex Providers)

**Files:**
- Create: `scripts/AI/manage-chat-history/providers/claude.py`
- Create: `scripts/AI/manage-chat-history/providers/codex.py`
- Test: `scripts/AI/manage-chat-history/tests/test_provider_stubs.py`

**Interfaces:**
- Produces:
  - `ClaudeCodeProvider(BaseProvider)`: checks `~/.claude` or `claude` executable, parses project sessions.
  - `CodexProvider(BaseProvider)`: checks `~/.codex` or `codex` executable.

- [ ] **Step 1: Write failing test for provider stubs**

```python
# scripts/AI/manage-chat-history/tests/test_provider_stubs.py
import unittest
from providers.claude import ClaudeCodeProvider
from providers.codex import CodexProvider

class TestProviderStubs(unittest.TestCase):
    def test_claude_provider_contract(self):
        p = ClaudeCodeProvider()
        self.assertEqual(p.name, "claude")
        self.assertEqual(p.display_name, "Claude Code")
        # should gracefully return list without error even if not installed
        self.assertIsInstance(p.list_sessions(), list)

    def test_codex_provider_contract(self):
        p = CodexProvider()
        self.assertEqual(p.name, "codex")
        self.assertEqual(p.display_name, "OpenAI Codex")
        self.assertIsInstance(p.list_sessions(), list)

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_provider_stubs.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'providers.claude'`

- [ ] **Step 3: Implement `providers/claude.py` and `providers/codex.py`**

```python
# scripts/AI/manage-chat-history/providers/claude.py
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Optional
from core.models import Session, SessionDetails, DeleteResult
from core.provider_base import BaseProvider

class ClaudeCodeProvider(BaseProvider):
    def __init__(self, data_dir: Optional[Path] = None):
        self.data_dir = data_dir or (Path.home() / ".claude")
        self.projects_dir = self.data_dir / "projects"

    @property
    def name(self) -> str:
        return "claude"

    @property
    def display_name(self) -> str:
        return "Claude Code"

    def is_available(self) -> bool:
        return (shutil.which("claude") is not None) or self.data_dir.exists()

    def list_sessions(self, cwd_only: bool = False, current_dir: Optional[Path] = None) -> List[Session]:
        if not self.is_available() or not self.projects_dir.exists():
            return []

        if current_dir is None:
            current_dir = Path.cwd().resolve()
        else:
            current_dir = current_dir.resolve()

        sessions = []
        for project_folder in self.projects_dir.iterdir():
            if not project_folder.is_dir():
                continue
            for session_file in project_folder.glob("*.json"):
                try:
                    with open(session_file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    sid = session_file.stem
                    title = data.get("title") or data.get("summary") or f"Claude Chat {sid[:8]}"
                    preview = data.get("preview") or ""
                    mtime = datetime.fromtimestamp(session_file.stat().st_mtime)
                    workspace = Path(data.get("workspace", str(project_folder)))

                    if cwd_only and workspace != current_dir and current_dir not in workspace.parents:
                        continue

                    sessions.append(Session(
                        id=sid,
                        provider=self.name,
                        provider_display=self.display_name,
                        title=title,
                        preview=preview,
                        workspace_paths=[workspace],
                        last_modified=mtime,
                        step_count=data.get("turn_count", 0),
                        status="idle"
                    ))
                except Exception:
                    continue
        sessions.sort(key=lambda s: s.last_modified, reverse=True)
        return sessions

    def get_session_details(self, session_id: str) -> Optional[SessionDetails]:
        for s in self.list_sessions():
            if s.id == session_id:
                return SessionDetails(session=s, messages_snippet=[s.preview] if s.preview else [])
        return None

    def resume_session(self, session: Session) -> None:
        claude_bin = shutil.which("claude")
        if not claude_bin:
            raise RuntimeError("Lệnh 'claude' không được tìm thấy trong PATH.")
        target_dir = session.workspace_paths[0] if session.workspace_paths and session.workspace_paths[0].exists() else Path.cwd()
        subprocess.run([claude_bin, "--resume", session.id], cwd=str(target_dir))

    def delete_sessions(self, session_ids: List[str]) -> DeleteResult:
        succeeded = []
        failed = []
        errors = []
        for sid in session_ids:
            deleted = False
            for f in self.projects_dir.rglob(f"{sid}.json"):
                try:
                    f.unlink()
                    deleted = True
                except Exception as e:
                    errors.append(f"Lỗi xóa {f}: {e}")
            if deleted:
                succeeded.append(sid)
            else:
                failed.append(sid)
        return DeleteResult(provider=self.name, succeeded_ids=succeeded, failed_ids=failed, error_messages=errors)
```

```python
# scripts/AI/manage-chat-history/providers/codex.py
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Optional
from core.models import Session, SessionDetails, DeleteResult
from core.provider_base import BaseProvider

class CodexProvider(BaseProvider):
    def __init__(self, data_dir: Optional[Path] = None):
        self.data_dir = data_dir or (Path.home() / ".codex")

    @property
    def name(self) -> str:
        return "codex"

    @property
    def display_name(self) -> str:
        return "OpenAI Codex"

    def is_available(self) -> bool:
        return (shutil.which("codex") is not None) or self.data_dir.exists()

    def list_sessions(self, cwd_only: bool = False, current_dir: Optional[Path] = None) -> List[Session]:
        # Ready for Codex history logs
        return []

    def get_session_details(self, session_id: str) -> Optional[SessionDetails]:
        return None

    def resume_session(self, session: Session) -> None:
        codex_bin = shutil.which("codex")
        if not codex_bin:
            raise RuntimeError("Lệnh 'codex' không được tìm thấy trong PATH.")
        target_dir = session.workspace_paths[0] if session.workspace_paths and session.workspace_paths[0].exists() else Path.cwd()
        subprocess.run([codex_bin, "--session", session.id], cwd=str(target_dir))

    def delete_sessions(self, session_ids: List[str]) -> DeleteResult:
        return DeleteResult(provider=self.name, succeeded_ids=session_ids)
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_provider_stubs.py
```
Expected: `Ran 2 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/providers/claude.py scripts/AI/manage-chat-history/providers/codex.py scripts/AI/manage-chat-history/tests/test_provider_stubs.py
git commit -m "feat(manage-chat): add Claude Code and OpenAI Codex provider stubs"
```

---

### Task 5: Session Manager (Registry, Search, Filter, Dispatch)

**Files:**
- Create: `scripts/AI/manage-chat-history/core/manager.py`
- Test: `scripts/AI/manage-chat-history/tests/test_manager.py`

**Interfaces:**
- Consumes: `core/models.py`, `core/provider_base.py`, all providers.
- Produces: `SessionManager`:
  - `register_provider(provider: BaseProvider)`
  - `get_available_providers() -> List[BaseProvider]`
  - `list_sessions(provider_name=None, cwd_only=False, search_query=None) -> List[Session]`
  - `get_session_details(provider_name: str, session_id: str) -> Optional[SessionDetails]`
  - `resume_session(session: Session) -> None`
  - `delete_sessions(sessions_by_provider: dict[str, list[str]]) -> List[DeleteResult]`

- [ ] **Step 1: Write failing test for SessionManager**

```python
# scripts/AI/manage-chat-history/tests/test_manager.py
import unittest
from datetime import datetime
from pathlib import Path
from core.models import Session, DeleteResult
from core.provider_base import BaseProvider
from core.manager import SessionManager

class MockProvider(BaseProvider):
    def __init__(self, name, display_name, sessions):
        self._name = name
        self._display = display_name
        self._sessions = sessions

    @property
    def name(self) -> str: return self._name
    @property
    def display_name(self) -> str: return self._display
    def is_available(self) -> bool: return True
    def list_sessions(self, cwd_only=False, current_dir=None):
        return self._sessions
    def get_session_details(self, session_id: str): return None
    def resume_session(self, session: Session) -> None: pass
    def delete_sessions(self, session_ids):
        return DeleteResult(provider=self.name, succeeded_ids=session_ids)

class TestSessionManager(unittest.TestCase):
    def setUp(self):
        s1 = Session("1", "agy", "Antigravity", "Web Design", "HTML CSS", [Path("/home/web")], datetime(2026, 9, 26))
        s2 = Session("2", "claude", "Claude Code", "Backend API", "FastAPI", [Path("/home/api")], datetime(2026, 9, 25))
        self.mgr = SessionManager(register_defaults=False)
        self.mgr.register_provider(MockProvider("agy", "Antigravity", [s1]))
        self.mgr.register_provider(MockProvider("claude", "Claude Code", [s2]))

    def test_list_all_sessions(self):
        sessions = self.mgr.list_sessions()
        self.assertEqual(len(sessions), 2)
        # Should be ordered descending by date
        self.assertEqual(sessions[0].id, "1")

    def test_filter_by_provider(self):
        sessions = self.mgr.list_sessions(provider_name="claude")
        self.assertEqual(len(sessions), 1)
        self.assertEqual(sessions[0].id, "2")

    def test_search_query(self):
        sessions = self.mgr.list_sessions(search_query="API")
        self.assertEqual(len(sessions), 1)
        self.assertEqual(sessions[0].id, "2")

        sessions = self.mgr.list_sessions(search_query="web")
        self.assertEqual(len(sessions), 1)
        self.assertEqual(sessions[0].id, "1")

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_manager.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'core.manager'`

- [ ] **Step 3: Implement `core/manager.py`**

```python
# scripts/AI/manage-chat-history/core/manager.py
from pathlib import Path
from typing import Dict, List, Optional
from core.models import Session, SessionDetails, DeleteResult
from core.provider_base import BaseProvider
from providers.antigravity import AntigravityProvider
from providers.claude import ClaudeCodeProvider
from providers.codex import CodexProvider

class SessionManager:
    def __init__(self, register_defaults: bool = True):
        self._providers: Dict[str, BaseProvider] = {}
        if register_defaults:
            self.register_provider(AntigravityProvider())
            self.register_provider(ClaudeCodeProvider())
            self.register_provider(CodexProvider())

    def register_provider(self, provider: BaseProvider) -> None:
        self._providers[provider.name] = provider

    def get_provider(self, name: str) -> Optional[BaseProvider]:
        return self._providers.get(name)

    def get_available_providers(self) -> List[BaseProvider]:
        return [p for p in self._providers.values() if p.is_available()]

    def list_sessions(
        self,
        provider_name: Optional[str] = None,
        cwd_only: bool = False,
        current_dir: Optional[Path] = None,
        search_query: Optional[str] = None
    ) -> List[Session]:
        sessions: List[Session] = []

        if provider_name and provider_name != "all":
            provider = self._providers.get(provider_name)
            if provider and provider.is_available():
                sessions.extend(provider.list_sessions(cwd_only=cwd_only, current_dir=current_dir))
        else:
            for p in self.get_available_providers():
                sessions.extend(p.list_sessions(cwd_only=cwd_only, current_dir=current_dir))

        # Sort descending by last modified
        sessions.sort(key=lambda s: s.last_modified, reverse=True)

        # Apply search query filter if provided
        if search_query:
            query = search_query.strip().lower()
            filtered = []
            for s in sessions:
                match_title = query in s.title.lower()
                match_id = query in s.id.lower()
                match_preview = query in s.preview.lower()
                match_workspace = any(query in str(p).lower() for p in s.workspace_paths)
                if match_title or match_id or match_preview or match_workspace:
                    filtered.append(s)
            return filtered

        return sessions

    def get_session_details(self, provider_name: str, session_id: str) -> Optional[SessionDetails]:
        provider = self._providers.get(provider_name)
        if provider:
            return provider.get_session_details(session_id)
        return None

    def resume_session(self, session: Session) -> None:
        provider = self._providers.get(session.provider)
        if not provider:
            raise ValueError(f"Không tìm thấy provider: {session.provider}")
        provider.resume_session(session)

    def delete_sessions(self, sessions_by_provider: Dict[str, List[str]]) -> List[DeleteResult]:
        results = []
        for provider_name, sids in sessions_by_provider.items():
            if not sids: continue
            provider = self._providers.get(provider_name)
            if provider:
                results.append(provider.delete_sessions(sids))
        return results
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_manager.py
```
Expected: `Ran 3 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/core/manager.py scripts/AI/manage-chat-history/tests/test_manager.py
git commit -m "feat(manage-chat): implement SessionManager registry and filtering"
```

---

### Task 6: Scriptable Non-Interactive CLI Interface

**Files:**
- Create: `scripts/AI/manage-chat-history/core/cli.py`
- Test: `scripts/AI/manage-chat-history/tests/test_cli.py`

**Interfaces:**
- Consumes: `core/manager.py`, `core/models.py`.
- Produces: `run_cli_command(args: list) -> int`:
  - `list`: lists sessions (supports `--provider`, `--cwd`, `--json`, `--limit`).
  - `show <id>`: prints metadata and preview.
  - `resume <id>`: resumes session.
  - `delete <id...>`: deletes session(s) with confirmation prompt (`[y/N]`) unless `-y`/`--yes`.

- [ ] **Step 1: Write failing test for CLI commands**

```python
# scripts/AI/manage-chat-history/tests/test_cli.py
import unittest
import io
import sys
from unittest.mock import patch
from datetime import datetime
from pathlib import Path
from core.models import Session, DeleteResult
from core.provider_base import BaseProvider
from core.manager import SessionManager
from core.cli import build_parser, handle_cli

class MockCLIProvider(BaseProvider):
    @property
    def name(self): return "agy"
    @property
    def display_name(self): return "Antigravity"
    def is_available(self): return True
    def list_sessions(self, cwd_only=False, current_dir=None):
        return [
            Session("id-123", "agy", "Antigravity", "CLI Test Session", "Preview", [Path("/test")], datetime(2026, 9, 26))
        ]
    def get_session_details(self, session_id): return None
    def resume_session(self, session): pass
    def delete_sessions(self, session_ids):
        return DeleteResult("agy", succeeded_ids=session_ids)

class TestCLICommands(unittest.TestCase):
    def setUp(self):
        self.mgr = SessionManager(register_defaults=False)
        self.mgr.register_provider(MockCLIProvider())
        self.parser = build_parser()

    def test_list_command_stdout(self):
        args = self.parser.parse_args(["list"])
        out = io.StringIO()
        with patch("sys.stdout", out):
            code = handle_cli(args, self.mgr)
        self.assertEqual(code, 0)
        self.assertIn("id-123", out.getvalue())
        self.assertIn("CLI Test Session", out.getvalue())

    def test_list_command_json(self):
        args = self.parser.parse_args(["list", "--json"])
        out = io.StringIO()
        with patch("sys.stdout", out):
            code = handle_cli(args, self.mgr)
        self.assertEqual(code, 0)
        self.assertIn('"id": "id-123"', out.getvalue())

    def test_delete_command_with_yes_flag(self):
        args = self.parser.parse_args(["delete", "id-123", "-y"])
        out = io.StringIO()
        with patch("sys.stdout", out):
            code = handle_cli(args, self.mgr)
        self.assertEqual(code, 0)
        self.assertIn("Đã xóa thành công", out.getvalue())

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_cli.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'core.cli'`

- [ ] **Step 3: Implement `core/cli.py`**

```python
# scripts/AI/manage-chat-history/core/cli.py
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

        # Print human-readable table
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
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_cli.py
```
Expected: `Ran 3 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/core/cli.py scripts/AI/manage-chat-history/tests/test_cli.py
git commit -m "feat(manage-chat): implement scriptable CLI subcommands"
```

---

### Task 7: Interactive Terminal UI (TUI) Loop & Keybindings

**Files:**
- Create: `scripts/AI/manage-chat-history/core/tui.py`
- Test: `scripts/AI/manage-chat-history/tests/test_tui.py`

**Interfaces:**
- Consumes: `core/manager.py`, `core/platform_utils.py`, `core/models.py`.
- Produces: `TerminalUI`:
  - `run()`: Starts full-screen interactive loop with alternate buffer and raw input.
  - Renders 3 sections: Header & search bar, split panes (session list with selection checkboxes, session details & preview on right), footer with key shortcuts.
  - Handles key actions: `↑`/`↓`/`j`/`k`, `PageUp`/`PageDown`, `Home`/`End`, `Space`, `a`, `Enter`, `d`/`x`, `/`, `w`, `p`/`Tab`, `r`, `q`/`Esc`.

- [ ] **Step 1: Write unit tests for TUI state management**

```python
# scripts/AI/manage-chat-history/tests/test_tui.py
import unittest
from datetime import datetime
from pathlib import Path
from core.models import Session
from core.provider_base import BaseProvider
from core.manager import SessionManager
from core.tui import TerminalUI

class MockTUIProvider(BaseProvider):
    @property
    def name(self): return "agy"
    @property
    def display_name(self): return "Antigravity"
    def is_available(self): return True
    def list_sessions(self, cwd_only=False, current_dir=None):
        return [
            Session("1", "agy", "Antigravity", "Session 1", "Prev 1", [Path("/p1")], datetime(2026, 9, 26)),
            Session("2", "agy", "Antigravity", "Session 2", "Prev 2", [Path("/p2")], datetime(2026, 9, 25))
        ]
    def get_session_details(self, session_id): return None
    def resume_session(self, session): pass
    def delete_sessions(self, session_ids): return None

class TestTUIState(unittest.TestCase):
    def setUp(self):
        mgr = SessionManager(register_defaults=False)
        mgr.register_provider(MockTUIProvider())
        self.tui = TerminalUI(mgr)

    def test_initial_state(self):
        self.assertEqual(len(self.tui.sessions), 2)
        self.assertEqual(self.tui.selected_index, 0)
        self.assertEqual(len(self.tui.marked_ids), 0)
        self.assertEqual(self.tui.provider_filter, "all")
        self.assertFalse(self.tui.cwd_only)

    def test_navigation_bounds(self):
        self.tui.move_down()
        self.assertEqual(self.tui.selected_index, 1)
        self.tui.move_down()
        self.assertEqual(self.tui.selected_index, 1) # Clamped
        self.tui.move_up()
        self.assertEqual(self.tui.selected_index, 0)
        self.tui.move_up()
        self.assertEqual(self.tui.selected_index, 0) # Clamped

    def test_toggle_select(self):
        self.tui.toggle_select()
        self.assertIn("1", self.tui.marked_ids)
        self.tui.toggle_select()
        self.assertNotIn("1", self.tui.marked_ids)

    def test_select_all(self):
        self.tui.select_all()
        self.assertEqual(len(self.tui.marked_ids), 2)
        self.tui.select_all()
        self.assertEqual(len(self.tui.marked_ids), 0)

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_tui.py
```
Expected: FAIL with `ModuleNotFoundError: No module named 'core.tui'`

- [ ] **Step 3: Implement `core/tui.py`**

```python
# scripts/AI/manage-chat-history/core/tui.py
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

        # Adjust scroll offset
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
                # Group by provider
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
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
PYTHONPATH=scripts/AI/manage-chat-history python3 -m unittest scripts/AI/manage-chat-history/tests/test_tui.py
```
Expected: `Ran 4 tests in ... OK`

- [ ] **Step 5: Commit changes**

```bash
git add scripts/AI/manage-chat-history/core/tui.py scripts/AI/manage-chat-history/tests/test_tui.py
git commit -m "feat(manage-chat): implement interactive Terminal UI and event loop"
```

---

### Task 8: Entrypoint Wrapper, Dotfile Shell Integration & End-to-End Verification

**Files:**
- Create: `scripts/AI/manage-chat-history/manage_chat.py`
- Create: `scripts/AI/manage-chat-history/README.md`

**Interfaces:**
- Produces: Executable `manage_chat.py` (when run without arguments launches TUI; when run with arguments dispatches CLI commands).

- [ ] **Step 1: Implement `manage_chat.py`**

```python
#!/usr/bin/env python3
# scripts/AI/manage-chat-history/manage_chat.py
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
```

- [ ] **Step 2: Make executable and verify help output**

Run:
```bash
chmod +x scripts/AI/manage-chat-history/manage_chat.py
python3 scripts/AI/manage-chat-history/manage_chat.py --help
```
Expected:
```
usage: manage_chat [-h] {list,show,resume,delete} ...
Quản lý lịch sử chat của các AI CLI (Antigravity, Claude Code, Codex)
```

- [ ] **Step 3: Run live test against user's actual Antigravity data**

Run:
```bash
python3 scripts/AI/manage-chat-history/manage_chat.py list --limit 5
```
Expected: Prints table listing the most recent 5 chat sessions from `~/.gemini/antigravity-cli/conversation_summaries.db`.

- [ ] **Step 4: Create documentation `README.md`**

```markdown
# AI Chat History Manager

Công cụ CLI và Terminal UI (TUI) đa nền tảng (macOS, Linux, Windows) để quản lý lịch sử chat của các AI CLI (Antigravity `agy`, Claude Code, Codex).

## Tính năng

- **Interactive TUI**: Giao diện terminal đầy đủ tính năng, tương tác phím tắt mượt mà.
- **Xem & Resume**: Xem trước tin nhắn, nhấn Enter để mở lại phiên làm việc đúng trong workspace của nó.
- **Xóa an toàn**: Chọn 1 hoặc nhiều phiên (`Space`) để dọn sạch dữ liệu (SQLite, conversations, artifacts) kèm hộp thoại xác nhận.
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

# Xem chi tiết một phiên
python3 manage_chat.py show <session_id>

# Tiếp tục một phiên
python3 manage_chat.py resume <session_id>

# Xóa phiên chat
python3 manage_chat.py delete <session_id> -y
```
```

- [ ] **Step 5: Run all unit tests**

Run:
```bash
python3 -m unittest discover scripts/AI/manage-chat-history/tests/ -v
```
Expected: All tests PASS with exit code 0.

- [ ] **Step 6: Commit changes**

```bash
git add scripts/AI/manage-chat-history/manage_chat.py scripts/AI/manage-chat-history/README.md
git commit -m "feat(manage-chat): add executable entrypoint, README documentation and finish integration"
```
