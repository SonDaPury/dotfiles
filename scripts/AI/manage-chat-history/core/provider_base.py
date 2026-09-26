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
