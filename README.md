# Claude Code Sandbox

Portable Docker sandbox for running Claude Code in any project directory.

## Setup

```bash
git clone https://github.com/YOUR_USERNAME/claude-sandbox.git ~/.claude-sandbox
~/.claude-sandbox/install.sh
```

The install script is lightweight and safe to run. It doesn't install system packages or require sudo. The only things it touches on your system are:
- Two symlinks in `~/.local/bin` (so `claude-sandbox` and `chrome-debug` are on your PATH)
- One line appended to your shell rc file (`export PATH="$HOME/.local/bin:$PATH"`) if not already present
- A `config.env` file inside `~/.claude-sandbox` with your preferences
- A Docker image build (everything else lives inside the container)

To uninstall, remove `~/.claude-sandbox`, the two symlinks, and the PATH line from your shell rc.

The install script will:
1. Make all scripts executable
2. Symlink `claude-sandbox` and `chrome-debug` to `~/.local/bin/`
3. Add `~/.local/bin` to your PATH (in `.zshrc` or `.bashrc`)
4. Prompt you to configure (all fields have smart defaults — just hit Enter to accept):
   - **Git name** — defaults to your existing `git config` or OS username
   - **Git email** — defaults to your existing `git config` or `user@hostname`
   - **Chrome path (host machine)** — auto-detects Chrome, Canary, or Chromium on your host for the `chrome-debug` command
   - **Dev server port forwarding** — enable/disable port forwarding for dev servers inside the container (defaults to enabled, port 3000). Disable if you run dev servers outside the sandbox.
   - **Container shell** — choose between zsh (with oh-my-zsh) or bash
   - **Tmux** — whether to wrap Claude in a tmux session (agent teams always uses tmux)
   - **Tmux config** — use the sandbox's preconfigured setup or mount your own `tmux.conf`
5. Save your config to `config.env` (gitignored, stays local)
6. Optionally build the Docker image

You can change any of these later with `claude-sandbox settings`.

## Usage

```bash
cd ~/any-project
claude-sandbox
```

That's it. Your current directory becomes `/workspace` inside the container.

If tmux is enabled (the default), Claude launches inside a **tmux session** —
you can detach with `Ctrl+A, D` and reattach with `tmux attach -t claude`.

Multiple instances are supported — each auto-picks the next available port.

> **Note:** `--dangerously-skip-permissions` is enabled by default. The container
> provides isolation, but mounted volumes (your project dir, `~/.claude`) are
> writable. A warning banner is shown on each startup.

```bash
claude-sandbox                    # Start Claude Code in current directory
claude-sandbox settings           # Edit sandbox configuration interactively
claude-sandbox status             # Show all running sandbox instances
claude-sandbox stop               # Stop all running instances
claude-sandbox stop 3001          # Stop instance on a specific port
claude-sandbox login              # Re-authenticate
claude-sandbox shell              # Open a shell inside the container
claude-sandbox build              # Rebuild image (to update Claude Code version)
claude-sandbox --help             # Show full help with all commands and options
AGENT_TEAMS=1 claude-sandbox      # Start with experimental agent teams (forces tmux)
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
- **Multi-instance** — run multiple sandboxes simultaneously (each auto-picks an available dev server port to avoid conflicts)
- **Interactive settings** — `claude-sandbox settings` lets you edit all configuration after install
- **Shell choice** — use zsh (with oh-my-zsh) or bash inside the container
- **Optional tmux session** — Claude can run inside tmux with [Tokyo Night](https://github.com/janoamaral/tokyo-night-tmux) theme (git + time widgets); `Ctrl+A` prefix, vim-style pane navigation (`h/j/k/l`), intuitive splits (`|` and `-`), mouse toggle (`m`); host timezone is passed through. Bring your own `tmux.conf` or use the sandbox defaults. Tmux is always enabled when using agent teams.
- **neovim as default editor** — `Ctrl+G` in Claude opens nvim; mouse off by default for native terminal copy/paste, `F2` to toggle mouse on
- **oh-my-zsh** — robbyrussell theme with git, z, history, and dirhistory plugins (when using zsh)
- **Fast paste** — zsh magic functions disabled for snappy clipboard paste
- **Shell history** — persists across container restarts with dedup and cross-session sharing
- **UTF-8 locale** — full Unicode support with en_US.UTF-8 locale configured
- **Plugin support** — host Claude Code plugins are automatically available; claude-mem search works with SQLite text fallback when Chroma is unavailable
- **Chrome DevTools** — browser MCP works from inside the container
- **Optional dev server forwarding** — forward a container port to your host for dev servers started inside the sandbox; can be disabled if you run dev servers externally

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
| `settings.sh` | Interactive settings editor for post-install configuration |
| `chrome-debug` | Launch Chrome with Docker-accessible remote debugging |
| `chrome-bridge.mjs` | HTTP/WS proxy that rewrites Host headers for Chrome |
| `tmux.conf` | Tmux configuration: Tokyo Night theme, keybindings, plugins |
| `Dockerfile` | Node 22 slim + git + neovim + tmux + zsh + bash + oh-my-zsh + FiraCode Nerd Font + bun + uv + claude-code |
| `entrypoint.sh` | Container startup: git config, shell setup, neovim config, tmux config loading, plugin path fixes, MCP setup, claude-mem Docker fixes |
| `config.env` | Your local config (gitignored, created by install.sh) |

## Customization

Run `claude-sandbox settings` to interactively change any configuration option. Or edit `config.env` directly.

Edit `tmux.conf` to change the tmux theme, keybindings, or plugins. You can also point to your own tmux config via `claude-sandbox settings`.

Edit `entrypoint.sh` to change default MCP servers, editor, or container startup logic.

Edit `Dockerfile` to add system packages or change the Node.js version. Rebuild with `claude-sandbox build` after changes.
