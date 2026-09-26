import unittest
from datetime import datetime, timedelta
from pathlib import Path
from core.platform_utils import uri_to_path, truncate_text, format_relative_time

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

if __name__ == "__main__":
    unittest.main()
