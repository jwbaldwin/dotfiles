# .bashrc

# Edit and Source bashrc
alias ebash="vim ~/.bashrc"
alias sbash="source ~/.bashrc"


# User specific aliases and functions
alias v="nvim"
alias vim="nvim"
alias vi="nvim"
alias gg="./gradlew"
alias lsa='ls -a'
alias personal="cd ~/repos/personal"

alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/* | less -r'
alias gl='git log --stat --color'
alias gs='git status -sb'
alias ga='git add -A'
alias gcm='git commit -m'
alias gacm='git add -A && git commit -m'
alias gpush='git push'
alias gpull='git pull'
alias gcane='git commit --ammend --no-edit'
alias gpr='hub pull-request'
alias gm="git checkout master && git pull"
alias gmain="git checkout main && git pull"

# Start a new branch with last commit, then revert the commit in the previous branch
function branchify {
  git checkout -b $1 && git checkout - && git reset --hard HEAD~ && git checkout -
}
# Source global definitions
#if [ -f /etc/bashrc ]; then
    #. /etc/bashrc
#fi

export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME/.go

export ERL_AFLAGS="-kernel shell_history enabled"


PATH=$PATH:/home/username/bin:/usr/local/homebrew:$GOROOT/bin:$GOPATH/bin:~/.emacs.d/bin
export PATH
