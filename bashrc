#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History & terminal ergonomics
shopt -s checkwinsize
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

# Color aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Modern CLI alternatives
command -v bat >/dev/null 2>&1 && alias cat=bat

PS1='[\u@\h \W]\$ '

# Source environment files if they exist
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Shell history search
command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"

# Sci-fi / Cyberpunk prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Auto-start or attach to existing tmux session
if [ -z "$TMUX" ] && [ -z "$NVIM" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
    if command -v tmux >/dev/null 2>&1; then
        exec tmux new-session -A -s main
    fi
fi
