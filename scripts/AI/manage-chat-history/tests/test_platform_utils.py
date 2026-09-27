import unittest
from datetime import datetime, timedelta
from pathlib import Path
from core.platform_utils import uri_to_path, truncate_text, format_relative_time, decode_escape_sequence

class TestPlatformUtils(unittest.TestCase):
    def test_uri_to_path_unix(self):
        p = uri_to_path("file:///Users/son/Workspaces/my_project")
        self.assertEqual(str(p), "/Users/son/Workspaces/my_project")

    def test_uri_to_path_windows(self):
        p = uri_to_path("file:///C:/Users/son/Workspaces/my_project")
        # Path resolution handles Windows drive format or unix clean path
        self.assertTrue("C:" in str(p) or "Users/son/Workspaces" in str(p))

    def test_uri_to_path_with_percent_encoding(self):
        p = uri_to_path("file:///Users/son/My%20Folder/project%201")
        self.assertEqual(str(p), "/Users/son/My Folder/project 1")

    def test_truncate_text(self):
        self.assertEqual(truncate_text("Hello World", 5), "He...")
        self.assertEqual(truncate_text("Hi", 5), "Hi")
        self.assertEqual(truncate_text("Exact", 5), "Exact")

    def test_format_relative_time(self):
        now = datetime.now()
        self.assertIn(":", format_relative_time(now))
        old = datetime(2025, 1, 15, 10, 30)
        self.assertIn("15/01", format_relative_time(old))

    def test_decode_escape_sequence(self):
        # Application Cursor Keys (SS3)
        self.assertEqual(decode_escape_sequence('\x1bOA'), 'UP')
        self.assertEqual(decode_escape_sequence('\x1bOB'), 'DOWN')
        self.assertEqual(decode_escape_sequence('\x1bOC'), 'RIGHT')
        self.assertEqual(decode_escape_sequence('\x1bOD'), 'LEFT')
        self.assertEqual(decode_escape_sequence('\x1bOH'), 'HOME')
        self.assertEqual(decode_escape_sequence('\x1bOF'), 'END')

        # Standard CSI Sequences
        self.assertEqual(decode_escape_sequence('\x1b[A'), 'UP')
        self.assertEqual(decode_escape_sequence('\x1b[B'), 'DOWN')
        self.assertEqual(decode_escape_sequence('\x1b[C'), 'RIGHT')
        self.assertEqual(decode_escape_sequence('\x1b[D'), 'LEFT')
        self.assertEqual(decode_escape_sequence('\x1b[H'), 'HOME')
        self.assertEqual(decode_escape_sequence('\x1b[F'), 'END')
        self.assertEqual(decode_escape_sequence('\x1b[5~'), 'PAGE_UP')
        self.assertEqual(decode_escape_sequence('\x1b[6~'), 'PAGE_DOWN')
        self.assertEqual(decode_escape_sequence('\x1b[3~'), 'DELETE')

        # Standalone ESC or invalid
        self.assertEqual(decode_escape_sequence('\x1b'), 'ESC')
        self.assertEqual(decode_escape_sequence('\x1b[99~'), 'ESC')
        self.assertEqual(decode_escape_sequence('plain'), 'plain')

if __name__ == "__main__":
    unittest.main()
