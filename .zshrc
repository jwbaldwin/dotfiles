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

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
export ZSH_DISABLE_COMPFIX=true

# disable OMZ auto-update checks
zstyle ':omz:update' mode disabled

# ===== Plugins =====
plugins=(
  direnv
  git
  jj
  zsh-syntax-highlighting
  zsh-autosuggestions
  z
)

source "$ZSH/oh-my-zsh.sh"

# Note: OMZ already calls compinit, so we skip redundant call here

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

# ===== nvm (lazy-loaded on first use) =====
# export NVM_DIR="$HOME/.nvm"
# nvm() {
#   unset -f nvm node npm npx
#   [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
#   nvm "$@"
# }
# node() { nvm exec --silent --silent "$0" "$@"; }
# npm()  { nvm exec --silent --silent "$0" "$@"; }
# npx()  { nvm exec --silent --silent "$0" "$@"; }

# ===== Aliases directory =====
for file in "$HOME"/.aliases/*(N); do
  [[ -r "$file" ]] && source "$file"
done

# Misc env
export ERL_AFLAGS="-kernel shell_history enabled"
[ -d "$HOMEBREW_PREFIX/opt/go/libexec" ] && export GOROOT="$HOMEBREW_PREFIX/opt/go/libexec"

# Dotfiles helpers
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias df='dotfiles'

# Rust & cargo
[ -r "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# AI API token source
[ -r "$HOME/.ai_keys.sh" ] && source "$HOME/.ai_keys.sh"

# Local env (kept as-is)
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ===== Keybindings for faster history search =====
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# ===== Compile zshrc for faster loading =====
if [[ ! -f "$HOME/.zshrc.zwc" ]] || [[ "$HOME/.zshrc" -nt "$HOME/.zshrc.zwc" ]]; then
  zcompile "$HOME/.zshrc"
fi
