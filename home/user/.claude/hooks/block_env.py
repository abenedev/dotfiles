#!/usr/bin/env python3
"""PreToolUse hook: never let Claude touch a real .env file.

Blocks file tools (Read, Edit, Write, NotebookEdit, Grep, Glob) aimed at a .env file, and
Bash commands that name one (cat .env, grep X .env.local, source .env, cp .env …).
Example/template files stay allowed: .env.example, .env.local.example, .env.sample,
.env.template, .env.dist, .env.defaults.
"""

from __future__ import annotations

import json
import os
import re
import sys

ALLOWED_SUFFIXES = (".example", ".sample", ".template", ".dist", ".defaults")

# A .env file name: ".env", ".env.local", ".env.production.local", or a glob like ".env*".
ENV_NAME = re.compile(r"^\.env([.*][A-Za-z0-9_.*-]*)?$")
# The same name inside a shell command: not preceded by a word character (so
# `process.env` and `os.environ` don't count) and ending at a word boundary.
ENV_IN_COMMAND = re.compile(r"(?<![A-Za-z0-9_])\.env(?:[.*][A-Za-z0-9_.*-]*)?(?![A-Za-z0-9_])")


def is_real_env(name: str) -> bool:
    name = name.strip().strip("'\"")
    base = os.path.basename(name.rstrip("/"))
    if not ENV_NAME.match(base):
        return False
    return not base.lower().endswith(ALLOWED_SUFFIXES)


def command_touches_env(command: str) -> str | None:
    for match in ENV_IN_COMMAND.finditer(command):
        if is_real_env(match.group(0)):
            return match.group(0)
    return None


def deny(reason: str) -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    sys.exit(0)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        return
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input") or {}
    message = (
        "Blocked: .env files must never be touched (read, searched, edited or listed). "
        "Work with the example file (.env.example) instead, and ask the user for any "
        "value only their .env holds."
    )

    if tool == "Bash":
        found = command_touches_env(str(tool_input.get("command", "")))
        if found:
            deny(f"{message} (command mentions {found})")
        return

    # Grep's "pattern" is a content regex, not a file: only Glob's is a path.
    keys = ["file_path", "notebook_path", "path", "glob"]
    if tool == "Glob":
        keys.append("pattern")
    paths = [tool_input.get(key) for key in keys if isinstance(tool_input.get(key), str)]
    for value in paths:
        # Glob/Grep patterns may be paths ("**/.env*") or a bare name.
        for part in re.split(r"[\s,{}]+", value):
            if part and is_real_env(part):
                deny(f"{message} ({part})")


if __name__ == "__main__":
    main()
