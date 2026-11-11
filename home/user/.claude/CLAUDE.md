# Global rules

## Never touch `.env` files

Never read, print, search, edit, write, copy, move, delete or source a `.env` file (`.env`, `.env.local`, `.env.production`, `.env.*`), with any tool and in any way: no `cat`, `grep`, `sed`, `head`, `diff`, scripts or "filtered/masked" output, not even to check whether a variable is set. This holds in every project, whatever the reason.

- The only env files that may be read or edited are the example/template ones (`.env.example`, `.env.local.example`, `.env.sample`, `.env.template`…).
- To know how a project is configured, read the example file and the code that reads the variables.
- When a change needs a new or different variable, update the example file and tell the user exactly what to add or change in their own `.env`; never do it for them.
- When a task depends on a value only the real `.env` holds, ask the user.
- This is enforced by `~/.claude/hooks/block_env.py` (PreToolUse hook) and `permissions.deny` in `~/.claude/settings.json`. Never edit, disable or work around them.

## Biome, never ESLint

In JavaScript/TypeScript projects, lint and format with Biome (`@biomejs/biome`) using its default configuration. Never use ESLint (or Prettier).

- Never add a Biome config file (`biome.json`, `biome.jsonc`, `.biome*`). Pass any option the project really needs as a CLI flag in the `package.json` script instead (e.g. `--css-parse-tailwind-directives=true` for Tailwind v4 CSS).
- Without a config, Biome doesn't read `.gitignore`: name the source paths in the scripts (e.g. `biome check src tests …`) so build output like `.next/` isn't scanned.
- When a project still has ESLint, remove it: its packages (`eslint`, `eslint-config-*`, `eslint-plugin-*`), its config file and its `eslint-disable` comments, which become `// biome-ignore <rule>: <reason>` where the rule still applies.
- Suppress a Biome rule only with `biome-ignore` and a real reason; fix the code otherwise.

## Don't run the linter

Never run the linter after coding, in any project: no `npm run lint`, `biome check`, `biome lint` or `biome check --write` / `npm run format` (nor ESLint, ruff…). The user runs it themselves. Run it only when the user explicitly asks for it in the current request. Type checks, tests and builds are still fine.
