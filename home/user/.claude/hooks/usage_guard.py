#!/usr/bin/env python3
"""Stop Claude Code sessions before the claude.ai usage limits run out.

Modes (the first argument):
  statusline  Status line command: caches the rate limits Claude Code sends to the status
              line (5-hour and weekly used percentage) and prints the status line.
  pre-tool    PreToolUse hook: once a limit reaches the threshold (90% by default), every
              tool call is denied except reading and editing a todo.md file, with
              instructions to write what was ongoing and what remains there.
  stop        Stop hook: if a tool call was denied in this session and no todo.md was
              written yet, the turn is not allowed to end before the handoff is written.

Settings (environment variables):
  CLAUDE_USAGE_GUARD_THRESHOLD  percentage that triggers the guard (default 90)
  CLAUDE_USAGE_GUARD=off        disables the guard (also: touch ~/.claude/state/usage-guard-off)

The rate limits only reach the status line for claude.ai Pro/Max subscribers, after the
first API response of a session; without them the guard never triggers. The cache is as
fresh as the last status line refresh (after each assistant message).
"""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

STATE_DIR = Path.home() / ".claude" / "state"
CACHE = STATE_DIR / "rate-limits.json"
MARKERS = STATE_DIR / "usage-guard"
OFF_FILE = STATE_DIR / "usage-guard-off"
WINDOWS = {"five_hour": "5-hour", "seven_day": "weekly"}
# Tools that may still run once the limit is reached, on a todo.md file only.
HANDOFF_TOOLS = {"Read", "Edit", "Write", "MultiEdit"}


def threshold() -> float:
    try:
        return float(os.environ.get("CLAUDE_USAGE_GUARD_THRESHOLD", "90"))
    except ValueError:
        return 90.0


def disabled() -> bool:
    return os.environ.get("CLAUDE_USAGE_GUARD", "").lower() in {"off", "0", "false"} or OFF_FILE.exists()


def read_stdin() -> dict:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return {}
    return data if isinstance(data, dict) else {}


def write_atomic(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=path.name, suffix=".tmp")
    with os.fdopen(fd, "w") as handle:
        json.dump(data, handle)
    os.replace(tmp, path)


def current_limits() -> dict[str, dict]:
    """The cached windows whose reset time hasn't passed."""
    try:
        cached = json.loads(CACHE.read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    now = time.time()
    limits = {}
    for key in WINDOWS:
        window = cached.get(key)
        if not isinstance(window, dict):
            continue
        resets_at = window.get("resets_at")
        if isinstance(resets_at, (int, float)) and resets_at <= now:
            continue
        if isinstance(window.get("used_percentage"), (int, float)):
            limits[key] = window
    return limits


def exceeded() -> list[str]:
    """Descriptions of the windows at or above the threshold, e.g. '5-hour limit at 92%'."""
    if disabled():
        return []
    limit = threshold()
    found = []
    for key, window in current_limits().items():
        used = window["used_percentage"]
        if used >= limit:
            when = ""
            resets_at = window.get("resets_at")
            if isinstance(resets_at, (int, float)):
                when = time.strftime(" (resets %Y-%m-%d %H:%M)", time.localtime(resets_at))
            found.append(f"{WINDOWS[key]} limit at {used:.0f}%{when}")
    return found


def project_root(cwd: str) -> Path:
    try:
        top = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=3,
        )
        if top.returncode == 0 and top.stdout.strip():
            return Path(top.stdout.strip())
    except (OSError, subprocess.SubprocessError):
        pass
    return Path(cwd or ".")


def marker(session_id: str, kind: str) -> Path:
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_") or "unknown"
    return MARKERS / f"{safe}.{kind}"


def statusline() -> None:
    data = read_stdin()
    limits = data.get("rate_limits")
    if isinstance(limits, dict) and any(key in limits for key in WINDOWS):
        try:
            write_atomic(CACHE, {**{k: limits[k] for k in WINDOWS if k in limits}, "updated_at": time.time()})
        except OSError:
            pass
    cwd = data.get("cwd") or (data.get("workspace") or {}).get("current_dir") or os.getcwd()
    line = f"\033[01;32m{os.environ.get('USER', '')}@{socket.gethostname().split('.')[0]}\033[00m:\033[01;34m{cwd}\033[00m"
    usage = []
    for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
        window = (limits or {}).get(key) if isinstance(limits, dict) else None
        if isinstance(window, dict) and isinstance(window.get("used_percentage"), (int, float)):
            used = window["used_percentage"]
            color = "31" if used >= threshold() else "33" if used >= threshold() - 15 else "37"
            usage.append(f"\033[{color}m{label} {used:.0f}%\033[00m")
    if usage:
        line += "  " + " ".join(usage)
    print(line)


def handoff_instructions(reasons: list[str], todo: Path) -> str:
    return (
        f"Usage guard: {', '.join(reasons)} (threshold {threshold():.0f}%). Stop the current "
        f"work now, without starting anything new. Write the handoff into {todo}: add a "
        "section '## Paused at the usage limit (<date and time>)' with what was ongoing (the "
        "task, the files changed and their state, anything half-done or untested, uncommitted "
        "changes) and the remaining work as '- [ ]' items, precise enough to resume in a new "
        "session; update the existing items instead of duplicating them. Only Read, Edit and "
        "Write on a todo.md file are allowed until the limit resets. Then end the turn and tell "
        "the user the work was paused and why."
    )


def pre_tool() -> None:
    data = read_stdin()
    reasons = exceeded()
    if not reasons:
        return
    session = str(data.get("session_id", ""))
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("path") or ""
    if tool in HANDOFF_TOOLS and Path(path).name.lower() == "todo.md":
        if tool != "Read":
            try:
                marker(session, "handoff").parent.mkdir(parents=True, exist_ok=True)
                marker(session, "handoff").touch()
            except OSError:
                pass
        return
    try:
        marker(session, "denied").parent.mkdir(parents=True, exist_ok=True)
        marker(session, "denied").touch()
    except OSError:
        pass
    todo = project_root(str(data.get("cwd", ""))) / "todo.md"
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": handoff_instructions(reasons, todo),
        },
        "systemMessage": f"Usage guard: {', '.join(reasons)}. Claude is writing the handoff to {todo}.",
    }))


def stop() -> None:
    data = read_stdin()
    if data.get("stop_hook_active"):
        return
    session = str(data.get("session_id", ""))
    reasons = exceeded()
    if not reasons or not marker(session, "denied").exists() or marker(session, "handoff").exists():
        return
    todo = project_root(str(data.get("cwd", ""))) / "todo.md"
    print(json.dumps({"decision": "block", "reason": handoff_instructions(reasons, todo)}))


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        {"statusline": statusline, "pre-tool": pre_tool, "stop": stop}[mode]()
    except KeyError:
        print(f"usage: {sys.argv[0]} statusline|pre-tool|stop", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
