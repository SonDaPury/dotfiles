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
