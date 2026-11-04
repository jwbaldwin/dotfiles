# mise and Node manager cleanup

The dotfiles now expect this setup:

- mise manages only project runtimes: node, pnpm, python, and tools pinned in repo `mise.toml` files. Its global config is just `node = "lts"` and `pnpm = "latest"`.
- Homebrew installs global tools: `neovim`, `bun`, `tree-sitter-cli`, `mole`, `pi-coding-agent`, `agent-browser`, `ripgrep`.
- mise comes from its own installer at `~/.local/bin/mise`, not Homebrew. The Homebrew binary is larger and takes longer to start.
- No vite-plus, no asdf, no extra global pnpm installed into Homebrew's Node.

Shims stay first on `PATH` by design. On machines with endpoint security, every mise start costs 0.1–0.2s, so `mise activate` would add that cost to every prompt.

## Steps

Run these in a plain terminal. Use `/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME` wherever these steps say `df`, because the alias may not exist in your shell.

If you are an agent running inside pi, and `which pi` points into `~/.local/share/mise`, skip step 3. Ask James to run it after he exits pi, because removing the running pi breaks the session.

```sh
# 1. Pull dotfiles
cd ~ && df pull

# 2. Install global tools from Homebrew
brew install ripgrep neovim bun tree-sitter-cli mole pi-coding-agent agent-browser

# 3. Remove the mise copies of those tools (pi must not be running)
mise uninstall --all neovim bun mole tree-sitter viteplus npm:@earendil-works/pi-coding-agent 2>/dev/null || true

# 4. Switch mise from Homebrew to its own installer
curl -fsSL https://mise.run | sh
brew uninstall mise 2>/dev/null || true
hash -r

# 5. Remove extra version managers, if present
command -v vp >/dev/null && vp implode -y
brew uninstall asdf 2>/dev/null || true; rm -rf ~/.asdf
/opt/homebrew/bin/npm uninstall -g pnpm 2>/dev/null || true

# 6. Install global runtimes (name pnpm@latest, or mise keeps an older installed pnpm)
mise install node@lts pnpm@latest

# 7. Clear unused versions, rebuild shims and zsh completions
mise prune -y
mise reshim
rm -f ~/.zcompdump ~/.zshrc.zwc

# 8. Stop pi from checking for rg on every start
ln -sf /opt/homebrew/bin/rg ~/.pi/agent/bin/rg
```

## Manual checks

- `~/.config/mise/config.local.toml` is not tracked. If it pins `node = "…"`, delete that line.
- List global npm packages inside mise's Node installs:

  ```sh
  ls ~/.local/share/mise/installs/node/*/lib/node_modules
  ```

  Anything besides `npm` and `corepack` is a leftover. Common ones are `agent-browser`, `@earendil-works`, `@anthropic-ai` and `pnpm`. Remove each with that version's npm:

  ```sh
  ~/.local/share/mise/installs/node/<version>/bin/npm uninstall -g <package>
  ```

  Then run `mise reshim`.
- Search scripts and launch agents for old paths, and update or remove any hits:

  ```sh
  grep -rl -E 'homebrew/bin/mise|vite-plus|npm-earendil-works|\.bun/bin' ~/dev ~/Library/LaunchAgents ~/.config 2>/dev/null
  ```

## Verify

Open a new terminal, then run:

```sh
type -a pi nvim bun agent-browser mise | head
mise doctor | tail -5
ls ~/.local/share/mise/shims | grep -E '^(pi|nvim|bun|claude|agent-browser|vp|start)$'
```

Expected:

- `pi`, `nvim`, `bun` and `agent-browser` resolve to `/opt/homebrew/bin`.
- `mise` resolves to `~/.local/bin/mise`.
- `mise doctor` ends with "No problems found".
- The shims `grep` prints nothing.

## When done

Tell James this machine is finished. Only delete this file and commit the removal (`df rm cleanup.md && df commit -m "remove cleanup notes"`, then `df push`) once James confirms every machine is done.
