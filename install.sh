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

# ---------- User config ----------
CONFIG_FILE="$SANDBOX_DIR/config.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "--- Configuration ---"

    # Git identity — fall back to system git config, then OS username
    DEFAULT_NAME=$(git config --global user.name 2>/dev/null || echo "$(id -F 2>/dev/null || whoami)")
    DEFAULT_EMAIL=$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname -s)")

    read -p "Git name [$DEFAULT_NAME]: " GIT_NAME
    GIT_NAME="${GIT_NAME:-$DEFAULT_NAME}"

    read -p "Git email [$DEFAULT_EMAIL]: " GIT_EMAIL
    GIT_EMAIL="${GIT_EMAIL:-$DEFAULT_EMAIL}"

    # Chrome path — detect from common locations
    DEFAULT_CHROME=""
    for candidate in \
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
        "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
        "/Applications/Chromium.app/Contents/MacOS/Chromium" \
        "$(which google-chrome 2>/dev/null)" \
        "$(which chromium-browser 2>/dev/null)" \
        "$(which chromium 2>/dev/null)"; do
        if [ -n "$candidate" ] && [ -f "$candidate" ]; then
            DEFAULT_CHROME="$candidate"
            break
        fi
    done
    DEFAULT_CHROME="${DEFAULT_CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

    read -p "Chrome path [$DEFAULT_CHROME]: " CHROME_PATH
    CHROME_PATH="${CHROME_PATH:-$DEFAULT_CHROME}"

    # Dev server port
    read -p "Default dev server port [3000]: " DEV_PORT
    DEV_PORT="${DEV_PORT:-3000}"

    cat > "$CONFIG_FILE" << EOF
GIT_USER_NAME="$GIT_NAME"
GIT_USER_EMAIL="$GIT_EMAIL"
CHROME_PATH="$CHROME_PATH"
DEV_PORT=$DEV_PORT
EOF
    echo "Saved config to $CONFIG_FILE"
else
    echo "Config already exists at $CONFIG_FILE"
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
