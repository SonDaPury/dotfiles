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
