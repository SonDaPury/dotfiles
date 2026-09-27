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
            conn = sqlite3.connect(str(self.db_path), timeout=15.0)
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()
            cur.execute("""
                SELECT conversation_id, title, preview, step_count, last_modified_time, workspace_uris, status
                FROM conversation_summaries
                ORDER BY last_modified_time DESC;
            """)
            rows = cur.fetchall()
            conn.close()
        except Exception:
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
            if s.id == session_id or s.id.startswith(session_id):
                session = s
                break
        if not session:
            return None

        transcript_file = self.brain_dir / session.id / ".system_generated" / "logs" / "transcript.jsonl"
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
                            clean_text = content.replace("<USER_REQUEST>", "").replace("</USER_REQUEST>", "")
                            clean_text = " ".join(l.strip() for l in clean_text.splitlines() if l.strip())
                            if clean_text:
                                messages.append(f"{role}: {clean_text}")
                                if len(messages) >= 12:
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
                conv_file = self.conv_dir / f"{sid}.db"
                if conv_file.exists():
                    conv_file.unlink()
                for ext in (".db-shm", ".db-wal"):
                    extra = self.conv_dir / f"{sid}{ext}"
                    if extra.exists():
                        extra.unlink()

                brain_session_dir = self.brain_dir / sid
                if brain_session_dir.exists() and brain_session_dir.is_dir():
                    shutil.rmtree(brain_session_dir, ignore_errors=True)

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
