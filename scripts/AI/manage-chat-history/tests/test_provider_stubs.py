import unittest
from providers.claude import ClaudeCodeProvider
from providers.codex import CodexProvider

class TestProviderStubs(unittest.TestCase):
    def test_claude_provider_contract(self):
        p = ClaudeCodeProvider()
        self.assertEqual(p.name, "claude")
        self.assertEqual(p.display_name, "Claude Code")
        self.assertIsInstance(p.list_sessions(), list)

    def test_codex_provider_contract(self):
        p = CodexProvider()
        self.assertEqual(p.name, "codex")
        self.assertEqual(p.display_name, "OpenAI Codex")
        self.assertIsInstance(p.list_sessions(), list)

if __name__ == "__main__":
    unittest.main()
