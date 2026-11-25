# Linux Symlink Setup

Run these commands after cloning this repository to `~/Work/tmux` (adjust `REPO_DIR` if cloned elsewhere) to create all symlinks in their target Linux locations:

```bash
REPO_DIR="$HOME/Work/tmux"

# Create required target directories
mkdir -p \
  "$HOME/.config/tmux/plugins/tmux-which-key" \
  "$HOME/.local/bin"

# Ensure helper scripts are executable
chmod +x \
  "$REPO_DIR/scripts/tmux-whisper" \
  "$REPO_DIR/scripts/tmux-notify"

# Create symlinks
ln -sfn "$REPO_DIR/tmux.conf"                         "$HOME/.tmux.conf"
ln -sfn "$REPO_DIR/bashrc"                            "$HOME/.bashrc"
ln -sfn "$REPO_DIR/bash_profile"                      "$HOME/.bash_profile"
ln -sfn "$REPO_DIR/asoundrc"                          "$HOME/.asoundrc"
ln -sfn "$REPO_DIR/config/tmux-which-key/config.yaml" "$HOME/.config/tmux/plugins/tmux-which-key/config.yaml"
ln -sfn "$REPO_DIR/scripts/tmux-whisper"              "$HOME/.local/bin/tmux-whisper"
ln -sfn "$REPO_DIR/scripts/tmux-notify"               "$HOME/.local/bin/tmux-notify"
```

## Verify Symlinks

```bash
ls -l \
  "$HOME/.tmux.conf" \
  "$HOME/.bashrc" \
  "$HOME/.bash_profile" \
  "$HOME/.asoundrc" \
  "$HOME/.config/tmux/plugins/tmux-which-key/config.yaml" \
  "$HOME/.local/bin/tmux-whisper" \
  "$HOME/.local/bin/tmux-notify"
```

## Post-Link Setup (Arch WSL2)

```bash
# Optional CLI, audio, and Whisper dependencies
sudo pacman -S tmux fzf bat atuin alsa-utils alsa-plugins libpulse whisper-cpp

# Reload tmux configuration (inside tmux)
tmux source-file ~/.tmux.conf
```

- Inside tmux, press `Ctrl-b` then `I` (capital `i`) if TPM plugins have not been installed yet.
- On the first Whisper run (`Alt+v` or `Ctrl-a` then `v`), `tmux-whisper` automatically downloads `ggml-small.en.bin` to `~/.local/share/whisper/`.
