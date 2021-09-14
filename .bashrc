# .bashrc

# Source global definitions
#if [ -f /etc/bashrc ]; then
    #. /etc/bashrc
#fi

export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME/.go

export ERL_AFLAGS="-kernel shell_history enabled"


PATH=$PATH:/home/username/bin:/usr/local/homebrew:$GOROOT/bin:$GOPATH/bin:~/.emacs.d/bin:$HOME/.cargo/env:$HOME/.local/bin
export PATH
