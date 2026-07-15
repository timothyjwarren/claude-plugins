import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import git_cli_guard_logic as guard


class SplitSegmentsTests(unittest.TestCase):
    def test_single_command(self):
        self.assertEqual(
            guard.split_segments("git status"),
            [["git", "status"]],
        )

    def test_and_chain(self):
        self.assertEqual(
            guard.split_segments("git add . && git push"),
            [["git", "add", "."], ["git", "push"]],
        )

    def test_semicolon_chain(self):
        self.assertEqual(
            guard.split_segments("git commit -m x; gh pr create"),
            [["git", "commit", "-m", "x"], ["gh", "pr", "create"]],
        )

    def test_or_and_pipe(self):
        self.assertEqual(
            guard.split_segments("git status || git log | cat"),
            [["git", "status"], ["git", "log"], ["cat"]],
        )

    def test_quoted_string_preserved(self):
        self.assertEqual(
            guard.split_segments('git commit -m "fix: a && b"'),
            [["git", "commit", "-m", "fix: a && b"]],
        )


if __name__ == "__main__":
    unittest.main()
