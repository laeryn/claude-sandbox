#!/bin/zsh
set -e

# Git config
git config --global --add safe.directory '*'
[ -n "$GIT_USER_NAME" ] && git config --global user.name "$GIT_USER_NAME"
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"

# Oh-my-zsh config (written fresh each start to stay idempotent)
cat > /home/coder/.zshrc << 'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
plugins=(git z history dirhistory)
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR=nvim
export VISUAL=nvim

# History
export HISTSIZE=10000
export SAVEHIST=20000
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
ZSHRC

# Shell history persistence (mount a file to keep history across restarts)
if [ -n "$HISTFILE" ]; then
    touch "$HISTFILE"
    echo "export HISTFILE=$HISTFILE" >> /home/coder/.zshrc
fi

# Export editor vars for the current process too (so Claude Code sees them)
export EDITOR=nvim
export VISUAL=nvim

# Disable auto-update and install nag — version is pinned by the Docker image
export DISABLE_AUTOUPDATER=1
export DISABLE_INSTALLATION_CHECKS=true

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

# Neovim config: mouse with F2 toggle for terminal right-click access
mkdir -p /home/coder/.config/nvim
cat > /home/coder/.config/nvim/init.lua << 'NVIM'
vim.o.mouse = "a"

-- Press F2 to toggle mouse on/off (off = terminal handles right-click/selection)
vim.keymap.set({"n", "i", "v"}, "<F2>", function()
  if vim.o.mouse == "a" then
    vim.o.mouse = ""
    print("Mouse OFF - right-click menu available")
  else
    vim.o.mouse = "a"
    print("Mouse ON")
  end
end)
NVIM

# Tmux config: enable mouse scrollback and UTF-8
cat > /home/coder/.tmux.conf << 'TMUX'
set -g default-terminal "tmux-256color"
set -sg escape-time 10
set -gq utf8 on
# Toggle mouse mode with Ctrl-b m (off by default so terminal selection works)
set -g mouse off
bind m set -g mouse \; display "Mouse: #{?mouse,ON,OFF}"
TMUX

tmux new-session -s claude "claude --dangerously-skip-permissions $*"
exec zsh
