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


class ClassifyGitTests(unittest.TestCase):
    FLAT_SAFE_SUBCOMMANDS = [
        "add", "commit", "branch", "checkout", "fetch", "pull", "status",
        "diff", "log", "stash", "tag", "merge", "rebase", "reset", "show",
        "blame", "restore", "switch",
    ]

    def test_flat_safe_subcommands(self):
        for sub in self.FLAT_SAFE_SUBCOMMANDS:
            with self.subTest(sub=sub):
                self.assertTrue(guard.classify_git(["git", sub]))

    def test_flat_safe_subcommand_with_args(self):
        self.assertTrue(guard.classify_git(["git", "commit", "-m", "msg"]))

    def test_remote_bare_is_safe(self):
        self.assertTrue(guard.classify_git(["git", "remote"]))

    def test_remote_dash_v_is_safe(self):
        self.assertTrue(guard.classify_git(["git", "remote", "-v"]))

    def test_remote_show_is_safe(self):
        self.assertTrue(guard.classify_git(["git", "remote", "show"]))

    def test_remote_add_is_not_safe(self):
        self.assertFalse(
            guard.classify_git(["git", "remote", "add", "origin", "url"])
        )

    def test_remote_set_url_is_not_safe(self):
        self.assertFalse(
            guard.classify_git(["git", "remote", "set-url", "origin", "url"])
        )

    def test_clone_is_not_safe(self):
        self.assertFalse(guard.classify_git(["git", "clone", "url"]))

    def test_push_is_not_safe(self):
        self.assertFalse(guard.classify_git(["git", "push"]))

    def test_unrecognized_subcommand_is_not_safe(self):
        self.assertFalse(guard.classify_git(["git", "worktree"]))

    def test_bare_git_is_not_safe(self):
        self.assertFalse(guard.classify_git(["git"]))


class ClassifyGhTests(unittest.TestCase):
    SAFE_PAIRS = [
        ("pr", "view"), ("pr", "list"), ("pr", "diff"), ("pr", "checks"),
        ("pr", "status"),
        ("issue", "view"), ("issue", "list"), ("issue", "status"),
        ("repo", "view"), ("repo", "list"),
        ("run", "view"), ("run", "list"),
        ("workflow", "view"), ("workflow", "list"),
        ("release", "view"), ("release", "list"),
    ]

    def test_safe_pairs(self):
        for noun, verb in self.SAFE_PAIRS:
            with self.subTest(noun=noun, verb=verb):
                self.assertTrue(guard.classify_gh(["gh", noun, verb]))

    def test_safe_pair_with_extra_args(self):
        self.assertTrue(
            guard.classify_gh(["gh", "pr", "view", "123", "--comments"])
        )

    def test_unlisted_pair_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh", "pr", "create"]))

    def test_pr_comment_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh", "pr", "comment", "123"]))

    def test_repo_delete_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh", "repo", "delete"]))

    def test_gh_api_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh", "api", "repos/x/y"]))

    def test_gh_auth_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh", "auth", "login"]))

    def test_bare_pr_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh", "pr"]))

    def test_bare_gh_is_not_safe(self):
        self.assertFalse(guard.classify_gh(["gh"]))


if __name__ == "__main__":
    unittest.main()
