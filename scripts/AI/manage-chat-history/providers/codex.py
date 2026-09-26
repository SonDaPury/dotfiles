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
