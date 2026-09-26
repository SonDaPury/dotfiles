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
