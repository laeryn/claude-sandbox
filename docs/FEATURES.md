# Features

## Tokyo Night tmux theme with Nerd Fonts — 2026-04-05
Switched tmux theme from Dracula to Tokyo Night with git and time status bar widgets. Installs FiraCode Nerd Font in the container for proper icon rendering. Tmux config externalized to `tmux.conf` for easy customization. Uses TPM (Tmux Plugin Manager) and `Ctrl+A` prefix.
- Key files: `tmux.conf`, `Dockerfile`, `entrypoint.sh`, `claude-sandbox`

## tmux support — 2026-04-02
Added tmux to the container so users can run multiple panes within the same shell session.
- Key files: `Dockerfile`

## zsh as default shell — 2026-04-02
Changed the default shell from bash to zsh for the `coder` user, including zsh-compatible history persistence in the entrypoint.
- Key files: `Dockerfile`, `entrypoint.sh`
