#!/bin/zsh
set -e

# Git config
git config --global --add safe.directory '*'
[ -n "$GIT_USER_NAME" ] && git config --global user.name "$GIT_USER_NAME"
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"

# Shell history persistence
if [ -n "$HISTFILE" ]; then
    touch "$HISTFILE"
    echo "export HISTFILE=$HISTFILE" >> /home/coder/.zshrc
    echo "export HISTSIZE=10000" >> /home/coder/.zshrc
    echo "export SAVEHIST=20000" >> /home/coder/.zshrc
    echo "setopt APPEND_HISTORY" >> /home/coder/.zshrc
fi

# Fast paste and editor config
echo "export DISABLE_MAGIC_FUNCTIONS=true" >> /home/coder/.zshrc
echo "export EDITOR=nvim" >> /home/coder/.zshrc
echo "export VISUAL=nvim" >> /home/coder/.zshrc

# Disable auto-update — version is pinned by the Docker image
export DISABLE_AUTOUPDATER=1

# ---------- Fix plugin paths for container ----------
KM_FILE="/home/coder/.claude/plugins/known_marketplaces.json"
if [ -f "$KM_FILE" ] && grep -q "/Users/" "$KM_FILE" 2>/dev/null; then
    sed 's|/Users/[^/]*/\.claude/|/home/coder/.claude/|g' "$KM_FILE" > /tmp/km_fixed.json
    cp /tmp/km_fixed.json "$KM_FILE"
    rm /tmp/km_fixed.json
fi

# ---------- Set up MCP servers ----------
claude mcp remove chrome-devtools 2>/dev/null || true
claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest --browserUrl http://host.docker.internal:9222 2>/dev/null || true

if ! claude mcp list 2>/dev/null | grep -q "context7"; then
    claude mcp add context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null || true
fi

exec tmux new-session -s claude "claude --dangerously-skip-permissions $*"
