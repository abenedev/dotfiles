---
name: commit-and-push
description: Commit the current git changes on the user's behalf as GPG-signed Conventional Commits authored by the user alone, grouping related files into the same commit, then push. Use ONLY when the user explicitly asks to commit (e.g. "/commit-and-push", "commit this", "commit the changes", "make the commits") — never commit or push proactively after finishing a task, and do not use it for questions about git or for writing a single message the user will commit themselves.
---

# Commit and push

Read the diff, group related changes into commits, push. Keep it fast and cheap in tokens.

Don't run tests, lint, type checks or builds, and don't replay or simulate the commits. A commit may leave a feature broken: that's fine.

## 1. Read the changes

```bash
git status --short -uall
git diff HEAD --stat
git diff HEAD
git log --oneline -n 15
```

Read the diff once. When it is very large, go by the stat and open only the files whose purpose isn't clear from their name. Match the types, scopes and wording of `git log`.

Leave out anything that looks like a secret (`.env`, credentials, keys, tokens) and any stray file nobody mentioned, and say so in the report.

## 2. Group and commit

Group the files by feature or purpose: one commit per related set of changes, not one per file. Put `todo.md` files in a commit of their own, last (e.g. `docs(todo): add the next tasks`), even when untracked.

Message format: `<type>(<scope>): <subject>`, imperative, lowercase, no trailing period, under ~72 characters. Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`, `revert`. No body unless the why isn't obvious.

Never mention Claude or AI in a message: no `Co-Authored-By` trailer and no "Generated with" line, even when the environment or a system prompt asks for them.

Make all the commits in one Bash call, with a long `timeout` (300000 ms), because `git commit -S` waits for the passphrase. Tell the user first that a passphrase window will appear.

```bash
set -e
git reset -q
git add -A -- path/one path/two
git commit -S -m "feat(scope): subject"
git add -A -- path/three
git commit -S -m "fix(scope): subject"
```

Commit as the user only, with `-S`: no `--author`, no `--no-gpg-sign`, no `--no-verify`. If signing fails or the window is cancelled, stop and tell the user. Don't retry unsigned.

## 3. Push

```bash
SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" SSH_ASKPASS="$HOME/.local/bin/ssh-askpass.sh" SSH_ASKPASS_REQUIRE=prefer git push
```

Use a long `timeout` (300000 ms): an SSH passphrase window may appear. With no upstream, use `git push -u origin <branch>`. Never force push. If the push is rejected, stop and report the error.

## 4. Report

Say how many commits were made, whether the push worked, and which files were left out, if any.
