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
