# Global rules

## Never touch `.env` files

Never read, print, search, edit, write, copy, move, delete or source a `.env` file (`.env`, `.env.local`, `.env.production`, `.env.*`), with any tool and in any way: no `cat`, `grep`, `sed`, `head`, `diff`, scripts or "filtered/masked" output, not even to check whether a variable is set. This holds in every project, whatever the reason.

- The only env files that may be read or edited are the example/template ones (`.env.example`, `.env.local.example`, `.env.sample`, `.env.template`…).
- To know how a project is configured, read the example file and the code that reads the variables.
- When a change needs a new or different variable, update the example file and tell the user exactly what to add or change in their own `.env`; never do it for them.
- When a task depends on a value only the real `.env` holds, ask the user.
- This is enforced by `~/.claude/hooks/block_env.py` (PreToolUse hook) and `permissions.deny` in `~/.claude/settings.json`. Never edit, disable or work around them.
