export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_ANALYTICS=1

# Prevent duplicate PATH/FPATH entries
typeset -U PATH FPATH

# Detect silicon/intel without calling brew --prefix
if [ -d /opt/homebrew ]; then
  HOMEBREW_PREFIX=/opt/homebrew      # Apple Silicon default
elif [ -d /usr/local/Homebrew ] || [ -d /usr/local/Cellar ]; then
  HOMEBREW_PREFIX=/usr/local         # Intel default
else
  HOMEBREW_PREFIX=/opt/homebrew      # fallback; avoids calling `brew`
fi
export HOMEBREW_PREFIX

[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ] && FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
[ -d "$HOMEBREW_PREFIX/share/zsh/completions" ]     && FPATH="$HOMEBREW_PREFIX/share/zsh/completions:$FPATH"

export CLICOLOR=1

# ===== Consolidated PATH =====
export GOPATH="$HOME/.go"
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$HOME/.opencode/bin:$PNPM_HOME:$GOPATH/bin:$HOME/bin:/usr/local/bin:$PATH"

# ===== Completions =====
autoload -Uz compinit
compinit -C

# ===== Plugins (installed via Homebrew) =====
[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# z - directory jumping (zoxide is a faster alternative if installed)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# direnv (only when installed)
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# ===== Prompt (Starship with caching) =====
if [[ ! -f "$HOME/.cache/starship_init.zsh" ]] || [[ $(which starship) -nt "$HOME/.cache/starship_init.zsh" ]]; then
  mkdir -p "$HOME/.cache"
  starship init zsh > "$HOME/.cache/starship_init.zsh"
fi
source "$HOME/.cache/starship_init.zsh"

# ===== History configuration =====
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt EXTENDED_HISTORY      # Add timestamps to history

# ===== User configuration =====
export SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# Mise (cached for performance)
if [[ ! -f "$HOME/.cache/mise_activate.zsh" ]] || [[ $(which mise) -nt "$HOME/.cache/mise_activate.zsh" ]]; then
  mkdir -p "$HOME/.cache"
  mise activate zsh > "$HOME/.cache/mise_activate.zsh"
fi
source "$HOME/.cache/mise_activate.zsh"

# ===== Aliases directory =====
for file in "$HOME"/.aliases/*(N); do
  [[ -r "$file" ]] && source "$file"
done

# Misc env
export ERL_AFLAGS="-kernel shell_history enabled"
[ -d "$HOMEBREW_PREFIX/opt/go/libexec" ] && export GOROOT="$HOMEBREW_PREFIX/opt/go/libexec"

# bun completions
[ -s "/Users/jbaldwin/.bun/_bun" ] && source "/Users/jbaldwin/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Dotfiles helpers
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias df='dotfiles'

# Rust & cargo
[ -r "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# AI API token source
[ -r "$HOME/.ai_keys.sh" ] && source "$HOME/.ai_keys.sh"

# OpenCode experimental features
export OPENCODE_EXPERIMENTAL=1
export OPENCODE_EXPERIMENTAL_MARKDOWN=1

# Local env (kept as-is)
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ===== Keybindings for faster history search =====
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# ===== Zellij navigation (Ctrl+hjkl) =====
if [[ -n "$ZELLIJ" ]]; then
  zellij-nav-left()  { zellij action move-focus-or-tab left; }
  zellij-nav-down()  { zellij action move-focus down; }
  zellij-nav-up()    { zellij action move-focus up; }
  zellij-nav-right() { zellij action move-focus-or-tab right; }
  zle -N zellij-nav-left
  zle -N zellij-nav-down
  zle -N zellij-nav-up
  zle -N zellij-nav-right
  bindkey '^h' zellij-nav-left
  bindkey '^j' zellij-nav-down
  bindkey '^k' zellij-nav-up
  bindkey '^l' zellij-nav-right
  bindkey '^R' history-incremental-search-backward
  bindkey -M viins '^R' history-incremental-search-backward
  bindkey -M vicmd '^R' history-incremental-search-backward
fi

# ===== Compile zshrc for faster loading =====
if [[ ! -f "$HOME/.zshrc.zwc" ]] || [[ "$HOME/.zshrc" -nt "$HOME/.zshrc.zwc" ]]; then
  zcompile "$HOME/.zshrc"
fi
export PATH="$HOME/.zdocs/bin:$PATH"
if [[ "$WORK" != "true" ]] && command -v asdf &> /dev/null; then
  source "$(brew --prefix asdf)/libexec/asdf.sh"
fi
