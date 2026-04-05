#!/bin/bash
# Claude Code Sandbox — interactive settings editor
# Called via: claude-sandbox settings

set -e

SANDBOX_DIR="$HOME/.claude-sandbox"
CONFIG_FILE="$SANDBOX_DIR/config.env"

# --- ANSI ---
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# --- Helpers ---
header() {
    echo ""
    echo -e "${BOLD}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}│  Claude Code Sandbox — Settings                             │${RESET}"
    echo -e "${BOLD}└─────────────────────────────────────────────────────────────┘${RESET}"
}

load_config() {
    # Set defaults before sourcing
    GIT_USER_NAME=""
    GIT_USER_EMAIL=""
    CHROME_PATH=""
    ENABLE_DEV_PORT=1
    DEV_PORT=3000
    CONTAINER_SHELL="zsh"
    USE_TMUX=1
    TMUX_CONFIG=""

    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
GIT_USER_NAME="$GIT_USER_NAME"
GIT_USER_EMAIL="$GIT_USER_EMAIL"
CHROME_PATH="$CHROME_PATH"
ENABLE_DEV_PORT=$ENABLE_DEV_PORT
DEV_PORT=$DEV_PORT
CONTAINER_SHELL="$CONTAINER_SHELL"
USE_TMUX=$USE_TMUX
TMUX_CONFIG="$TMUX_CONFIG"
EOF
}

# Format a value for display — show "(not set)" for empty, friendly labels for flags
fmt_val() {
    local val="$1"
    if [ -z "$val" ]; then
        echo -e "${DIM}(not set)${RESET}"
    else
        echo -e "${CYAN}$val${RESET}"
    fi
}

fmt_bool() {
    local val="$1"
    local on_label="${2:-yes}"
    local off_label="${3:-no}"
    if [ "$val" = "1" ]; then
        echo -e "${GREEN}$on_label${RESET}"
    else
        echo -e "${YELLOW}$off_label${RESET}"
    fi
}

show_settings() {
    echo ""
    echo -e "  ${BOLD}1${RESET}  Git name            $(fmt_val "$GIT_USER_NAME")"
    echo -e "  ${BOLD}2${RESET}  Git email           $(fmt_val "$GIT_USER_EMAIL")"
    echo -e "  ${BOLD}3${RESET}  Chrome path (host)  $(fmt_val "$CHROME_PATH")"
    echo -e "  ${BOLD}4${RESET}  Dev server port     $(fmt_bool "$ENABLE_DEV_PORT" "enabled (port $DEV_PORT)" "disabled")"
    echo -e "  ${BOLD}5${RESET}  Container shell     $(fmt_val "$CONTAINER_SHELL")"
    echo -e "  ${BOLD}6${RESET}  Use tmux            $(fmt_bool "$USE_TMUX")"
    if [ "$USE_TMUX" = "1" ]; then
        local tmux_desc
        if [ -n "$TMUX_CONFIG" ]; then
            tmux_desc="custom: $TMUX_CONFIG"
        else
            tmux_desc="sandbox default"
        fi
        echo -e "  ${BOLD}7${RESET}  Tmux config         $(fmt_val "$tmux_desc")"
    fi
    echo ""
    echo -e "  ${BOLD}a${RESET}  Edit all settings"
    echo -e "  ${BOLD}q${RESET}  Save and quit"
    echo ""
}

# --- Per-setting editors ---
# Each function prompts for a new value using the same logic as install.sh

edit_git_name() {
    local default
    default="${GIT_USER_NAME:-$(git config --global user.name 2>/dev/null || id -F 2>/dev/null || whoami)}"
    read -p "Git name [$default]: " val
    GIT_USER_NAME="${val:-$default}"
}

edit_git_email() {
    local default
    default="${GIT_USER_EMAIL:-$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname -s)")}"
    read -p "Git email [$default]: " val
    GIT_USER_EMAIL="${val:-$default}"
}

edit_chrome_path() {
    local default="${CHROME_PATH}"
    if [ -z "$default" ]; then
        for candidate in \
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
            "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
            "/Applications/Chromium.app/Contents/MacOS/Chromium" \
            "$(which google-chrome 2>/dev/null)" \
            "$(which chromium-browser 2>/dev/null)" \
            "$(which chromium 2>/dev/null)"; do
            if [ -n "$candidate" ] && [ -f "$candidate" ]; then
                default="$candidate"
                break
            fi
        done
        default="${default:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
    fi
    read -p "Chrome path on host machine [$default]: " val
    CHROME_PATH="${val:-$default}"
}

edit_dev_port() {
    echo "The sandbox can forward a port so dev servers started inside the"
    echo "container are accessible on your host."
    local current
    if [ "$ENABLE_DEV_PORT" = "1" ]; then current="Y"; else current="n"; fi
    read -p "Enable dev server port forwarding? [Y/n] (current: $current): " val
    if [ "${val:-$current}" = "n" ] || [ "${val:-$current}" = "N" ]; then
        ENABLE_DEV_PORT=0
    else
        ENABLE_DEV_PORT=1
        local default="${DEV_PORT:-3000}"
        read -p "Default dev server port [$default]: " val
        DEV_PORT="${val:-$default}"
    fi
}

edit_container_shell() {
    local default="${CONTAINER_SHELL:-zsh}"
    echo "The container includes both bash and zsh (with oh-my-zsh)."
    read -p "Shell inside container [zsh/bash] (current: $default): " val
    val="${val:-$default}"
    if [ "$val" = "bash" ]; then
        CONTAINER_SHELL="bash"
    else
        CONTAINER_SHELL="zsh"
    fi
}

edit_use_tmux() {
    local current
    if [ "$USE_TMUX" = "1" ]; then current="Y"; else current="n"; fi
    echo "Tmux gives you split panes, scrollback, and a status bar."
    echo "Agent teams mode always uses tmux regardless of this setting."
    read -p "Open Claude in tmux by default? [Y/n] (current: $current): " val
    if [ "${val:-$current}" = "n" ] || [ "${val:-$current}" = "N" ]; then
        USE_TMUX=0
        TMUX_CONFIG=""
    else
        USE_TMUX=1
    fi
}

edit_tmux_config() {
    if [ "$USE_TMUX" != "1" ]; then
        echo -e "${YELLOW}Tmux is disabled. Enable it first (option 6).${RESET}"
        return
    fi
    echo "The sandbox includes a preconfigured tmux setup (Tokyo Night theme,"
    echo "custom prefix key, status widgets). You can use that, or mount your"
    echo "own tmux.conf instead."
    local current
    if [ -n "$TMUX_CONFIG" ]; then
        current="custom ($TMUX_CONFIG)"
    else
        current="sandbox default"
    fi
    echo "Current: $current"
    read -p "Use sandbox tmux config? [Y/n] " val
    if [ "${val:-Y}" = "n" ] || [ "${val:-Y}" = "N" ]; then
        local default="${TMUX_CONFIG:-$HOME/.tmux.conf}"
        read -p "Path to your tmux.conf [$default]: " val
        val="${val:-$default}"
        if [ ! -f "$val" ]; then
            echo -e "${YELLOW}Warning: $val not found. Keeping current setting.${RESET}"
        else
            TMUX_CONFIG="$val"
        fi
    else
        TMUX_CONFIG=""
    fi
}

edit_all() {
    echo ""
    echo -e "${BOLD}--- Editing all settings ---${RESET}"
    echo ""
    edit_git_name
    edit_git_email
    edit_chrome_path
    edit_dev_port
    edit_container_shell
    edit_use_tmux
    if [ "$USE_TMUX" = "1" ]; then
        edit_tmux_config
    fi
}

# --- Create default config if none exists ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}No config file found. Running initial setup...${RESET}"
    echo ""
    load_config
    edit_all
    save_config
    echo ""
    echo -e "${GREEN}Config saved to $CONFIG_FILE${RESET}"
    exit 0
fi

# --- Main loop ---
load_config
header

while true; do
    show_settings
    read -p "Select a setting to edit (1-7, a=all, q=quit): " choice

    case "$choice" in
        1) edit_git_name ;;
        2) edit_git_email ;;
        3) edit_chrome_path ;;
        4) edit_dev_port ;;
        5) edit_container_shell ;;
        6) edit_use_tmux ;;
        7) edit_tmux_config ;;
        a|A) edit_all ;;
        q|Q)
            save_config
            echo -e "${GREEN}Settings saved to $CONFIG_FILE${RESET}"
            exit 0
            ;;
        "")
            continue
            ;;
        *)
            echo -e "${RED}Invalid choice: $choice${RESET}"
            ;;
    esac
done
