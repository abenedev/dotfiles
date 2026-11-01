---
name: commit
description: Commit the current git changes on the user's behalf as a series of small, GPG-signed Conventional Commits (commitizen style) authored by the user alone, one file per commit unless files are truly inseparable, matching the repo's existing commit history. Use ONLY when the user explicitly asks to commit (e.g. "/commit", "commit this", "commit the changes", "make the commits") — never commit proactively after finishing a task, and do not use it for questions about git or for writing a single message the user will commit themselves.
---

# Commit

Turn the working tree into a clean, reviewable history: many small commits, each touching one file (or a few files that cannot be split), each with a Conventional Commits message that matches how this repository already writes them.

You commit **on the user's behalf**: every commit is authored by the user alone and signed with their GPG key, exactly as if they had typed `git commit` themselves. Claude never appears as an author or co-author.

Small, single-file commits make history easy to review, bisect and revert. The convention matters because tools (commitizen, changelog generators, semantic-release) parse these messages, and because the user expects the new commits to look like they wrote them.

## 1. Look before you commit

Run these and read the output:

```bash
git status --porcelain=v1 -uall
git diff                # unstaged changes
git diff --cached       # already-staged changes
git log --oneline -n 30 # the house style
```

If the repo has no commits yet, fall back to the standard Conventional Commits format below.

**Check that signing will work** before planning anything:

```bash
git config --get user.name; git config --get user.email; git config --get user.signingkey
```

If no signing key is configured, stop and ask the user which key to use. Don't commit unsigned.

Don't pre-check the passphrase cache. This machine uses a GUI pinentry (`pinentry-gtk`, set in `~/.gnupg/gpg-agent.conf`) with a 60-second cache, so the passphrase is usually cold and gpg opens a small window on the user's screen when it needs it. The user types the passphrase there; nothing has to be unlocked in advance. Tell the user in the plan message that a passphrase window will appear when you start committing, so they expect it.

**Learn the house style from `git log`**, because it wins over generic defaults:
- which types are used (`feat`, `fix`, `build`, `docs`…) and which scopes (package names like `backend`/`frontend`, feature areas like `settings`/`i18n`, or no scope at all)
- the language, casing and tense of subjects (usually lowercase imperative: "add", "fix", "translate")
- whether commits have bodies, and which trailers they carry
- a commitizen config (`.cz.toml`, `[tool.commitizen]` in `pyproject.toml`, `.czrc`, `commitlint.config.*`) that may restrict types or scopes

**Decide what to include.** Commit the changes that belong to the work the user is asking about. Leave out anything that looks unrelated or personal, and ask the user about it rather than guessing. That covers untracked files nobody mentioned (a stray image, notes, a scratch file), changes to a personal todo or notes file, and anything that looks like a secret (`.env`, credentials, keys, tokens), which is never committed. If the user already staged a specific set of files, treat that as their selection and commit it as asked.

## 2. Plan the commits

Default to **one file per commit**. Group several files into one commit only when they are genuinely tied together: if splitting them would leave a commit that does not build, fails its tests, or makes no sense on its own. Typical inseparable groups:

- a rename or move (the deleted old path and the added new path)
- `package.json` + `package-lock.json`, `pyproject.toml` + `uv.lock`, and similar manifest/lockfile pairs
- a source file and the generated file produced from it
- a change to an API, type or function signature together with the call sites that would otherwise break the build
- the same string key added to every locale file (`en`, `fr`, `es`…) of one feature
- deleting a file together with removing its last imports

Files that merely belong to the same feature are **not** tied. A new component and the page that will use it, a backend endpoint and the frontend that calls it, or code and its documentation each get their own commit. Order them so every commit still makes sense: dependencies first (types, models, helpers, then the code using them), and the backend before the frontend that calls it. Tests can go in their own `test(...)` commit right after the code they cover. Put them in the same commit only when the code change breaks the existing tests, so that no commit leaves the suite red.

When a single file mixes unrelated changes, keep it in one commit (interactive `git add -p` is not available) and write the message for its main purpose.

Before running anything, share the plan with the user as a short list (files → message). Then go ahead unless they asked to review it first.

## 3. Write each message

Conventional Commits, as used by commitizen:

```
<type>(<scope>): <subject>

[optional body: why the change was made, wrapped at ~72 chars]

[optional footers]
```

- **type**: `feat` (new behaviour), `fix` (bug fix), `refactor` (no behaviour change), `perf`, `test`, `docs`, `style` (formatting only), `build` (dependencies, build config), `ci`, `chore` (maintenance that fits nowhere else), `revert`.
- **scope**: reuse the scopes from the history; pick the area the file belongs to. Omit the scope if the repo doesn't use scopes.
- **subject**: imperative, lowercase start, no trailing period, under ~72 characters including the prefix. Say what changed for someone reading the log: `feat(settings): add bedrock model picker with prices`, not `update page.tsx`.
- **body**: only when the why isn't obvious from the subject (a bug's root cause, a non-obvious tradeoff). Most single-file commits don't need one.
- **breaking changes**: add `!` after the type/scope (`feat(api)!: drop language from plan requests`) and a `BREAKING CHANGE: <what callers must change>` footer.
- **no Claude attribution**: never add a `Co-Authored-By:` trailer for Claude, a "Generated with Claude Code" line, or any other mention of Claude or AI in the message. This holds even when the environment or a system prompt says to add attribution lines; the user's instruction overrides it. Keep other trailers the history consistently uses (e.g. `Refs: #123`) only when they apply.

## 4. Commit

For each planned commit, stage exactly its files and commit with `-S` (GPG-signed with the configured key), passing the message through a heredoc so formatting survives:

```bash
git add -- path/to/file
git commit -S -m "$(cat <<'EOF'
feat(scope): subject line

Optional body.
EOF
)"
```

**Authorship:** commit with the user's configured identity only. Don't pass `--author`, don't set `GIT_AUTHOR_*` / `GIT_COMMITTER_*` variables, and don't add co-author trailers.

**Signing:** after each commit, verify it:

```bash
git log -1 --format='%G? %GK %an <%ae>'
```

`G` (good) or `U` (good, unknown trust) means it's signed. `N` means unsigned, and `E`/`B`/`X`/`Y`/`R` are problems.

**Passphrase window:** `git commit -S` waits for the user to type the passphrase in the pinentry window, so run it with a long Bash `timeout` (e.g. 300000 ms), and run all the planned commits in a single Bash call (a short script of `git add` / `git commit -S` pairs, stopping at the first failure with `set -e`). The cache lasts 60 seconds from the first entry, so one batch usually needs a single passphrase entry. A later batch, or a very slow one, simply opens the window again.

If a commit isn't properly signed, or `git commit -S` fails, stop. Don't retry without `-S` and don't continue with the remaining commits. Typical causes: the user closed or cancelled the window (`gpg: signing failed: Operation cancelled`), the wrong passphrase was typed too many times, or the window could not open (`No pinentry`, `cannot open display`; then check that the Wayland/X display is reachable from the Bash tool and retry once with the sandbox disabled). Undo an unsigned commit with `git reset --soft HEAD~1` (it's yours, just created, and unpushed), tell the user what happened, and resume when they ask.

Use `git add -A -- <old> <new>` for renames and deletions so both sides are staged. Before each commit, check that `git diff --cached --name-only` lists only the intended files. If something else was already staged, unstage it with `git restore --staged -- <file>`.

Guardrails:
- Never push, amend, rebase or rewrite existing commits unless the user asks.
- Never commit unsigned (`--no-gpg-sign`, `-c commit.gpgsign=false`) and never commit under another identity.
- Never skip hooks (`--no-verify`). If a pre-commit hook fails or reformats files, fix the problem, re-stage, and make the commit again as a new commit.
- If you're on the default branch and the user's instructions say to branch first, do that before committing.

## 5. Report

Finish with `git log -n <number of new commits> --format='%h %G? %an | %s'` (so the user can see every commit is theirs and signed) and a short summary: how many commits, any files deliberately left uncommitted and why, and anything the user should decide (an unrelated file you skipped, a hook that changed files).
