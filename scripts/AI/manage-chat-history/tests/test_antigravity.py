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
