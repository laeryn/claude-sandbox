# Features

## tmux support — 2026-04-02
Added tmux to the container so users can run multiple panes within the same shell session.
- Key files: `Dockerfile`

## zsh as default shell — 2026-04-02
Changed the default shell from bash to zsh for the `coder` user, including zsh-compatible history persistence in the entrypoint.
- Key files: `Dockerfile`, `entrypoint.sh`
