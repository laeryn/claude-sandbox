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

```bash
# Multiple instances work — each auto-picks the next available port
cd ~/other-project
claude-sandbox

# Other commands
claude-sandbox login    # Re-authenticate
claude-sandbox bash     # Shell into container
claude-sandbox build    # Rebuild image (to update Claude Code version)
```

## Chrome DevTools (browser MCP)

```bash
chrome-debug            # Start Chrome with Docker-accessible remote debugging
chrome-debug stop       # Stop Chrome + bridge
```

The bridge handles macOS Chrome's localhost-only binding by proxying
through a Node.js HTTP/WebSocket bridge that rewrites Host headers.
Docker containers connect via `http://host.docker.internal:9222`.

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
| `Dockerfile` | Node 22 slim + git + vim + bun + claude-code |
| `entrypoint.sh` | Container startup: git config, plugin path fixes, MCP setup |
| `config.env` | Your local config (gitignored, created by install.sh) |

## Customization

Edit `config.env` to change git identity, Chrome path, or default port.

Edit `entrypoint.sh` to change default MCP servers or add container startup logic.

Edit `Dockerfile` to add system packages or change the Node.js version.
