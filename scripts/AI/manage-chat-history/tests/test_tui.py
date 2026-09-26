import unittest
from datetime import datetime
from pathlib import Path
from core.models import Session
from core.provider_base import BaseProvider
from core.manager import SessionManager
from core.tui import TerminalUI

class MockTUIProvider(BaseProvider):
    @property
    def name(self): return "agy"
    @property
    def display_name(self): return "Antigravity"
    def is_available(self): return True
    def list_sessions(self, cwd_only=False, current_dir=None):
        return [
            Session("1", "agy", "Antigravity", "Session 1", "Prev 1", [Path("/p1")], datetime(2026, 9, 26)),
            Session("2", "agy", "Antigravity", "Session 2", "Prev 2", [Path("/p2")], datetime(2026, 9, 25))
        ]
    def get_session_details(self, session_id): return None
    def resume_session(self, session): pass
    def delete_sessions(self, session_ids): return None

class TestTUIState(unittest.TestCase):
    def setUp(self):
        mgr = SessionManager(register_defaults=False)
        mgr.register_provider(MockTUIProvider())
        self.tui = TerminalUI(mgr)

    def test_initial_state(self):
        self.assertEqual(len(self.tui.sessions), 2)
        self.assertEqual(self.tui.selected_index, 0)
        self.assertEqual(len(self.tui.marked_ids), 0)
        self.assertEqual(self.tui.provider_filter, "all")
        self.assertFalse(self.tui.cwd_only)

    def test_navigation_bounds(self):
        self.tui.move_down()
        self.assertEqual(self.tui.selected_index, 1)
        self.tui.move_down()
        self.assertEqual(self.tui.selected_index, 1) # Clamped
        self.tui.move_up()
        self.assertEqual(self.tui.selected_index, 0)
        self.tui.move_up()
        self.assertEqual(self.tui.selected_index, 0) # Clamped

    def test_toggle_select(self):
        self.tui.toggle_select()
        self.assertIn("1", self.tui.marked_ids)
        self.tui.toggle_select()
        self.assertNotIn("1", self.tui.marked_ids)

    def test_select_all(self):
        self.tui.select_all()
        self.assertEqual(len(self.tui.marked_ids), 2)
        self.tui.select_all()
        self.assertEqual(len(self.tui.marked_ids), 0)

if __name__ == "__main__":
    unittest.main()
