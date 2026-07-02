#!/usr/bin/env python3
"""feat-doc-sync — Claude Code PostToolUse(Bash) hook.

When Claude makes a `feat:` commit in a personal repo under $GITHUB, inject an
instruction back into the SAME session asking it to run the post-commit-sync
workflow (README + VHS + portfolio proposal). No background process, no nested
`claude` — the running session does the work.

Only `feat:` commits trigger it. The sync's own README commit is a `docs:`
commit and is therefore ignored — no loop.

Reads the PostToolUse JSON on stdin; when it should fire, writes a PostToolUse
hookSpecificOutput.additionalContext object to stdout. Pure stdlib (no jq): the
hook must never hard-depend on a tool that might be absent on a fresh machine.
"""
import json
import os
import re
import subprocess
import sys


def git(cwd, *args):
    try:
        r = subprocess.run(["git", "-C", cwd, *args],
                           capture_output=True, text=True)
        return r.stdout.strip()
    except Exception:
        return ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return

    cmd = (data.get("tool_input") or {}).get("command", "") or ""
    cwd = data.get("cwd") or os.getcwd()

    # Only react to git commits (also matches `git -C <path> commit`).
    if not re.search(r"\bgit\b.*\bcommit\b", cmd):
        return

    repo_root = git(cwd, "rev-parse", "--show-toplevel")
    if not repo_root:
        return

    # Scope: personal projects under $GITHUB, never the portfolio repo itself.
    github = os.environ.get("GITHUB", os.path.expanduser("~/repos/github"))
    if repo_root != github and not repo_root.startswith(github + os.sep):
        return
    if os.path.basename(repo_root) == "portfolio":
        return

    # Only conventional-commit `feat` (optional scope, optional breaking '!').
    subject = git(repo_root, "log", "-1", "--format=%s")
    if not re.match(r"^feat(\([^)]*\))?!?:", subject):
        return

    sha = git(repo_root, "rev-parse", "--short", "HEAD")

    msg = (
        f"A feat commit ({sha}: {subject}) was just made in {repo_root}. "
        "Run the post-commit-sync workflow for this repository now, in this "
        "session: apply the relevance filter first, then update the README "
        "(soft template, create if missing), recompile any VHS .tape gifs, and "
        "propose portfolio EN+FR edits in the working tree WITHOUT committing the "
        "portfolio. Commit only the README/gif changes. If the change isn't "
        "doc-worthy, say so and do nothing."
    )

    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": msg,
        }
    }, sys.stdout)


if __name__ == "__main__":
    main()
