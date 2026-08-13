---
name: dotfiles
description: Manage James's home-directory dotfiles with the df/dotfiles bare Git repository. Use when checking, adding, committing, pulling, rebasing, or pushing dotfiles, or when editing files tracked by the dotfiles repo.
---

# Dotfiles

James's dotfiles use a bare Git repository at `~/.dotfiles` with `$HOME` as its work tree. `.zshrc` defines `dotfiles` and its short alias `df`.

## Rules

- Run dotfiles commands from `$HOME` through `df` or `dotfiles`; do not use `jj` or plain `git`
- Add explicit paths only; never run `df add .` or `df add -A`
- Preserve unrelated staged, unstaged, and untracked home-directory files
- Before committing, review `df status --short --branch` and `df diff --cached`
- Use lowercase, concrete commit messages without conventional-commit prefixes

## Workflow

```sh
cd "$HOME"
df status --short --branch
df diff -- <exact-paths>
df add <exact-paths>
df diff --cached --check
df diff --cached -- <exact-paths>
df commit -m "short concrete message"
df push
```

If push is rejected because remote `main` moved:

```sh
df fetch origin
df log --oneline --left-right HEAD...FETCH_HEAD -10
df rebase --autostash FETCH_HEAD
df push origin main
```

Before rebasing, handle any untracked file that the remote would overwrite: move it to a safe temporary path, rebase, merge its contents into the newly tracked file, verify the result, then remove the temporary copy. Never delete or overwrite the user's local file.

Finish with:

```sh
df status --short --branch
df log -3 --oneline
```
