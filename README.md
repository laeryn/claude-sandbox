# Claude Code Sandbox

Portable Docker sandbox for running Claude Code in any project directory.

## Setup

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/claude-sandbox.git ~/.claude-sandbox

# Build the Docker image
~/.claude-sandbox/claude-sandbox build

# Add to PATH (add to your .zshrc)
export PATH="$HOME/.claude-sandbox:$PATH"
```

## Usage

```bash
# Run Claude Code in any project
cd ~/my-project
claude-sandbox

# Multiple instances (auto-picks next available port)
cd ~/other-project
claude-sandbox

# Other commands
claude-sandbox login    # Re-authenticate
claude-sandbox bash     # Shell into container
claude-sandbox build    # Rebuild image after changes
```

## Chrome DevTools (for browser MCP)

```bash
# Start Chrome with remote debugging bridge
chrome-debug

# Stop it
chrome-debug stop
```

The bridge handles macOS Chrome's localhost-only binding by proxying
through a Node.js HTTP/WebSocket bridge that rewrites Host headers.

## What's Inside

| File | Purpose |
|------|---------|
| `claude-sandbox` | Main run script — portable, run from any directory |
| `chrome-debug` | Launch Chrome with Docker-accessible remote debugging |
| `chrome-bridge.mjs` | HTTP/WS proxy that rewrites Host headers for Chrome |
| `Dockerfile` | Node 22 slim + git + vim + bun + claude-code |
| `entrypoint.sh` | Container startup: git config, plugin path fixes, MCP setup |

## Customization

Edit `entrypoint.sh` to change:
- Git identity (name/email)
- Default MCP servers
- Plugin path rewriting

Edit `Dockerfile` to add:
- Additional system packages
- Different Node.js version
- Extra global npm packages
