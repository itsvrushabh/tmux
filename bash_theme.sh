# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# --- Custom Bash Theme ---

# Text Colors
Reset='\[\e[0m\]'
Blue='\[\e[0;34m\]'
Cyan='\[\e[0;36m\]'
Green='\[\e[0;32m\]'
Yellow='\[\e[0;33m\]'
Purple='\[\e[0;35m\]'
Red='\[\e[0;31m\]'

# Function to show Git Branch and status indicators
parse_git_branch() {
     local status
     status=$(git status --porcelain -b 2>/dev/null) || return
     local header
     header=$(echo "$status" | head -n1)
     local branch="${header#\#\# }"
     branch="${branch%%...*}"
     local marks=""

     # Check if ahead of remote
     if [[ "$header" =~ ahead ]]; then
          marks+=" ↑"
     fi
     # Check for uncommitted changes
     if echo "$status" | grep -q '^ [MADRCU]'; then
          marks+=" ✚" # Unstaged changes
     fi
     # Check for staged changes
     if echo "$status" | grep -q '^[MADRCU]'; then
          marks+=" ●" # Staged changes
     fi
     # Check for untracked files
     if echo "$status" | grep -q '^??'; then
          marks+=" …" # Untracked files
     fi

     echo -e " ($branch$marks)"
}


# Define Icons (You can replace these with any emoji or symbol)
SuccessIcon="✔"
FailureIcon="✘"

# Function to determine which icon to show
prompt_status() {
    local exit_code="${1:-$?}"
    if [ "$exit_code" -eq 0 ]; then
        echo -ne "$Green$SuccessIcon$Reset" # Green check
    else
        echo -ne "$Red$FailureIcon$Reset" # Red cross
    fi
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Usage: 
# sleep 5 & spinner $!

export LANGUAGE=en_IN.UTF-8


# --- 1. Zoxide (Smarter 'cd') ---
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
  alias cd="z"
  alias ci="z -i" # Interactive jump using fzf
fi

# --- 2. Eza (Modern 'ls' replacement) ---
# Check if eza is installed to set aliases
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --git --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --icons'
fi

# --- 3. Bat (Better 'cat') ---
if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# --- 4. FD & FZF Integration ---
# Use 'fd' instead of 'find' for speed and to respect .gitignore
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Setup FZF UI with Bat Preview
# This shows a preview window on the right with syntax highlighting
if command -v bat >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
--preview 'bat --color=always --style=numbers --line-range :500 {}'"
else
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi

# --- 5. FZF Keybindings & Completion ---
# Load official Arch Linux integration for Bash
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
# Auto-start tmux
if [ -z "$TMUX" ] && [ -z "$NVIM" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
    if command -v tmux >/dev/null 2>&1; then
        exec tmux new-session -A -s default
    fi
fi

# export PS1="${Blue}\w${Yellow}\$(parse_git_branch)${Reset} "

# Final PS1 (prompt_status evaluates the exit status dynamically)
export PS1="\$(prompt_status \$?) ${Cyan}\w\$(parse_git_branch)${Reset} "
