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
