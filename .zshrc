export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_ANALYTICS=1

# Detect silicon/intel without calling brew --prefix
if [ -d /opt/homebrew ]; then
  HOMEBREW_PREFIX=/opt/homebrew      # Apple Silicon default
elif [ -d /usr/local/Homebrew ] || [ -d /usr/local/Cellar ]; then
  HOMEBREW_PREFIX=/usr/local         # Intel default
else
  HOMEBREW_PREFIX=/opt/homebrew         # fallback; avoids calling `brew`
fi
export HOMEBREW_PREFIX

[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ] && FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
[ -d "$HOMEBREW_PREFIX/share/zsh/completions" ]     && FPATH="$HOMEBREW_PREFIX/share/zsh/completions:$FPATH"

export CLICOLOR=1
export PATH=/usr/local/bin:$HOME/bin:$PATH

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
export ZSH_DISABLE_COMPFIX=true

# disable OMZ auto-update checks (was commented out previously)
zstyle ':omz:update' mode disabled

autoload -Uz compinit
compinit -C

# ===== Prompt (Starship) =====
eval "$(starship init zsh)"

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

# ===== User configuration =====
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"


# Mise
eval "$(mise activate zsh)"


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
for file in $HOME/.aliases/*; do
  [ -r "$file" ] && source "$file"
done

# Misc env
export ERL_AFLAGS="-kernel shell_history enabled"
[ -d "$HOMEBREW_PREFIX/opt/go/libexec" ] && export GOROOT="$HOMEBREW_PREFIX/opt/go/libexec"
export GOPATH="$HOME/.go"

# Dotfiles helpers
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias df='dotfiles'

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Rust & cargo
[ -r "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# AI API token source
[ -r "$HOME/.ai_keys.sh" ] && source "$HOME/.ai_keys.sh"

# Local env (kept as-is)
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# opencode
export PATH=/Users/jbaldwin/.opencode/bin:$PATH
