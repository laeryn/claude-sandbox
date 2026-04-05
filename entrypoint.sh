#!/bin/bash
set -e

SHELL_CHOICE="${CONTAINER_SHELL:-zsh}"

# Git config
git config --global --add safe.directory '*'
[ -n "$GIT_USER_NAME" ] && git config --global user.name "$GIT_USER_NAME"
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"

# Shell config
if [ "$SHELL_CHOICE" = "zsh" ]; then
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

    # Shell history persistence
    if [ -n "$HISTFILE" ]; then
        touch "$HISTFILE"
        echo "export HISTFILE=$HISTFILE" >> /home/coder/.zshrc
    fi
else
    # Bash config
    cat > /home/coder/.bashrc << 'BASHRC'
# Editor
export EDITOR=nvim
export VISUAL=nvim

# History
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Prompt
PS1='\[\033[01;32m\]\u@sandbox\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
BASHRC

    # Shell history persistence
    if [ -n "$HISTFILE" ]; then
        touch "$HISTFILE"
        echo "export HISTFILE=$HISTFILE" >> /home/coder/.bashrc
    fi
fi

# Export editor vars for the current process too (so Claude Code sees them)
export EDITOR=nvim
export VISUAL=nvim

# Disable auto-update and install nag — version is pinned by the Docker image
export DISABLE_AUTOUPDATER=1
export DISABLE_INSTALLATION_CHECKS=true

# ---------- Fix claude-mem in Docker ----------
# 1. SQLite file locking doesn't work on Docker-mounted volumes (macOS virtiofs).
#    Move Chroma data to a container-local path so it can write properly.
if [ -d /home/coder/.claude-mem ]; then
    rm -rf /home/coder/.claude-mem/chroma
    mkdir -p /tmp/claude-mem-chroma
    ln -sf /tmp/claude-mem-chroma /home/coder/.claude-mem/chroma
fi
# 2. The default MCP→Worker timeout (3s) is too short for search queries inside
#    a container. Raise to 30s so semantic search has time to respond.
export CLAUDE_MEM_HEALTH_TIMEOUT_MS=30000
# 3. claude-mem's Setup hook references setup.sh which doesn't ship with the
#    plugin. Create a no-op stub so the hook doesn't error on startup.
for _d in \
    /home/coder/.claude/plugins/marketplaces/thedotmack/plugin/scripts \
    /home/coder/.claude/plugins/cache/thedotmack/claude-mem/*/scripts; do
    [ -d "$_d" ] && [ ! -f "$_d/setup.sh" ] && \
        printf '#!/bin/bash\necho '\''{"continue":true,"suppressOutput":true}'\''\n' > "$_d/setup.sh" && \
        chmod +x "$_d/setup.sh"
done

# ---------- Fix plugin paths for container ----------
KM_FILE="/home/coder/.claude/plugins/known_marketplaces.json"
if [ -f "$KM_FILE" ] && grep -q "/Users/" "$KM_FILE" 2>/dev/null; then
    sed 's|/Users/[^/]*/\.claude/|/home/coder/.claude/|g' "$KM_FILE" > /tmp/km_fixed.json
    cp /tmp/km_fixed.json "$KM_FILE"
    rm /tmp/km_fixed.json
fi

# ---------- Set up MCP servers (skip if already configured) ----------
if ! claude mcp list 2>/dev/null | grep -q "chrome-devtools"; then
    claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest --browserUrl http://host.docker.internal:9222 2>/dev/null || true
fi

if ! claude mcp list 2>/dev/null | grep -q "context7"; then
    claude mcp add context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null || true
fi

# Neovim config: mouse off so Terminal.app handles selection and right-click natively
# Press F2 in neovim to toggle mouse on if needed
mkdir -p /home/coder/.config/nvim
cat > /home/coder/.config/nvim/init.lua << 'NVIM'
vim.o.mouse = ""

vim.keymap.set({"n", "i", "v"}, "<F2>", function()
  if vim.o.mouse == "a" then
    vim.o.mouse = ""
    print("Mouse OFF - terminal handles selection")
  else
    vim.o.mouse = "a"
    print("Mouse ON - neovim handles mouse")
  end
end)
NVIM

# Tmux config: use mounted file if available, otherwise copy from sandbox dir
if [ -f /home/coder/.tmux.conf.mount ]; then
    cp /home/coder/.tmux.conf.mount /home/coder/.tmux.conf
elif [ -f /home/coder/.claude-sandbox/tmux.conf ]; then
    cp /home/coder/.claude-sandbox/tmux.conf /home/coder/.tmux.conf
fi

if [ "${USE_TMUX:-1}" = "1" ]; then
    tmux new-session -s claude "claude --dangerously-skip-permissions $*"
    exec "$SHELL_CHOICE"
else
    exec claude --dangerously-skip-permissions "$@"
fi
