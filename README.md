# Claude Code Sandbox

Portable Docker sandbox for running Claude Code in any project directory.

## Setup

```bash
git clone https://github.com/YOUR_USERNAME/claude-sandbox.git ~/.claude-sandbox
~/.claude-sandbox/install.sh
```

The install script will:
1. Make all scripts executable
2. Symlink `claude-sandbox` and `chrome-debug` to `~/.local/bin/`
3. Add `~/.local/bin` to your PATH (in `.zshrc` or `.bashrc`)
4. Prompt you to configure (all fields have smart defaults — just hit Enter to accept):
   - **Git name** — defaults to your existing `git config` or OS username
   - **Git email** — defaults to your existing `git config` or `user@hostname`
   - **Chrome path** — auto-detects Chrome, Canary, or Chromium
   - **Dev server port** — defaults to 3000
5. Save your config to `config.env` (gitignored, stays local)
6. Optionally build the Docker image

## Usage

```bash
cd ~/any-project
claude-sandbox
```

That's it. Your current directory becomes `/workspace` inside the container.

Claude launches inside a **tmux session** — you can detach with `Ctrl+B, D` and
reattach with `tmux attach -t claude`.

Multiple instances are supported — each auto-picks the next available port.

> **Note:** `--dangerously-skip-permissions` is enabled by default. The container
> provides isolation, but mounted volumes (your project dir, `~/.claude`) are
> writable. A warning banner is shown on each startup.

```bash
claude-sandbox                  # Start Claude Code in current directory
claude-sandbox --agent-teams    # Start with experimental Agent Teams enabled
claude-sandbox status           # Show all running sandbox instances
claude-sandbox stop             # Stop all running instances
claude-sandbox stop 3001        # Stop instance on a specific port
claude-sandbox login            # Re-authenticate
claude-sandbox bash             # Shell into container (zsh)
claude-sandbox build            # Rebuild image (to update Claude Code version)
```

## Chrome DevTools (browser MCP)

```bash
chrome-debug            # Start Chrome with Docker-accessible remote debugging
chrome-debug stop       # Stop Chrome + bridge
```

The bridge handles macOS Chrome's localhost-only binding by proxying
through a Node.js HTTP/WebSocket bridge that rewrites Host headers.
Docker containers connect via `http://host.docker.internal:9222`.

## Features

- **Portable** — run from any directory, current folder becomes `/workspace`
- **Multi-instance** — run multiple sandboxes simultaneously on different ports
- **tmux session** — Claude runs inside tmux with Dracula theme (git + time widgets); `Ctrl-a` prefix, vim-style pane navigation (`h/j/k/l`), intuitive splits (`|` and `-`), mouse toggle (`m`)
- **neovim as default editor** — `Ctrl+G` in Claude opens nvim; mouse off by default for native terminal copy/paste, `F2` to toggle mouse on
- **oh-my-zsh** — robbyrussell theme with git, z, history, and dirhistory plugins
- **Fast paste** — zsh magic functions disabled for snappy clipboard paste
- **zsh shell** — default shell with persistent history across container restarts
- **Shell history** — persists across container restarts with dedup and cross-session sharing
- **UTF-8 locale** — full Unicode support with en_US.UTF-8 locale configured
- **Plugin support** — host Claude Code plugins are automatically available
- **Chrome DevTools** — browser MCP works from inside the container
- **Dev server access** — forwarded ports are accessible from your host machine

## Updating Claude Code

The Docker image pins whatever Claude Code version was current at build time.
To update:

```bash
claude-sandbox build
```

## Files

| File | Purpose |
|------|---------|
| `install.sh` | One-time setup: symlinks, PATH, config prompts, image build |
| `claude-sandbox` | Main run script — portable, run from any directory |
| `chrome-debug` | Launch Chrome with Docker-accessible remote debugging |
| `chrome-bridge.mjs` | HTTP/WS proxy that rewrites Host headers for Chrome |
| `Dockerfile` | Node 22 slim + git + vim + neovim + tmux + zsh + oh-my-zsh + bun + claude-code |
| `entrypoint.sh` | Container startup: git config, oh-my-zsh, neovim/tmux config, plugin path fixes, MCP setup |
| `config.env` | Your local config (gitignored, created by install.sh) |

## Customization

Edit `config.env` to change git identity, Chrome path, or default port.

Edit `entrypoint.sh` to change default MCP servers, editor, or container startup logic.

Edit `Dockerfile` to add system packages or change the Node.js version.
