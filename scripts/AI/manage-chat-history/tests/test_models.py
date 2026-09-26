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
