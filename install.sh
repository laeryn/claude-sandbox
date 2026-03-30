#!/bin/bash
# Install Claude Code Sandbox
# Run: git clone <repo> ~/.claude-sandbox && ~/.claude-sandbox/install.sh

set -e

SANDBOX_DIR="$HOME/.claude-sandbox"
BIN_DIR="$HOME/.local/bin"

# ---------- Verify location ----------
if [ ! -f "$SANDBOX_DIR/claude-sandbox" ]; then
    echo "Error: This script must be run from $SANDBOX_DIR"
    echo "  git clone <repo> ~/.claude-sandbox"
    echo "  ~/.claude-sandbox/install.sh"
    exit 1
fi

# ---------- Make scripts executable ----------
chmod +x "$SANDBOX_DIR/claude-sandbox"
chmod +x "$SANDBOX_DIR/chrome-debug"
chmod +x "$SANDBOX_DIR/entrypoint.sh"

# ---------- Create bin dir and symlinks ----------
mkdir -p "$BIN_DIR"
ln -sf "$SANDBOX_DIR/claude-sandbox" "$BIN_DIR/claude-sandbox"
ln -sf "$SANDBOX_DIR/chrome-debug" "$BIN_DIR/chrome-debug"
echo "Symlinked claude-sandbox and chrome-debug to $BIN_DIR"

# ---------- Ensure bin dir is in PATH ----------
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Claude Code Sandbox" >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo "Added $BIN_DIR to PATH in $SHELL_RC"
        echo "  Run: source $SHELL_RC (or open a new terminal)"
    else
        echo "$BIN_DIR already in PATH"
    fi
else
    echo "Warning: Could not find shell rc file. Add this to your shell config:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

# ---------- Build Docker image ----------
echo ""
read -p "Build the Docker image now? [Y/n] " BUILD
if [ "${BUILD:-Y}" != "n" ] && [ "${BUILD:-Y}" != "N" ]; then
    "$SANDBOX_DIR/claude-sandbox" build
fi

echo ""
echo "Done! Usage:"
echo "  claude-sandbox        # Run Claude Code in any project dir"
echo "  chrome-debug          # Start Chrome for browser MCP"
echo "  chrome-debug stop     # Stop Chrome"
