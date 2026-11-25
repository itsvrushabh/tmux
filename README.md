# tmux

Personal tmux, shell, Whisper dictation, and corner-notification dotfiles for Arch WSL2.

## File Locations & Symlinks

| Repository File | Linux Target Location | Purpose |
|---|---|---|
| [`tmux.conf`](tmux.conf) | `~/.tmux.conf` | Main tmux config (TPM, `tmux-which-key`, Whisper, corner notifications) |
| [`config/tmux-which-key/config.yaml`](config/tmux-which-key/config.yaml) | `~/.config/tmux/plugins/tmux-which-key/config.yaml` | `Ctrl-a` centered `display-menu` keybindings and submenus |
| [`scripts/tmux-whisper`](scripts/tmux-whisper) | `~/.local/bin/tmux-whisper` | Local Whisper voice dictation (`Alt+v` toggle / `Ctrl-a v` popup) |
| [`scripts/tmux-notify`](scripts/tmux-notify) | `~/.local/bin/tmux-notify` | Top-right notification bell badge, 5s corner preview, and `fzf` history (`Alt+n` / click / `Ctrl-a N`) |
| [`asoundrc`](asoundrc) | `~/.asoundrc` | Routes ALSA `default` to WSLg PulseAudio for `arecord` |
| [`bashrc`](bashrc) | `~/.bashrc` | Interactive bash config, `atuin`, and auto-attach `tmux` |
| [`bash_profile`](bash_profile) | `~/.bash_profile` | Login shell startup and deduplicated `PATH` env sourcing |

See [docs/symlinks.md](docs/symlinks.md) for the full symlink creation and setup commands.
