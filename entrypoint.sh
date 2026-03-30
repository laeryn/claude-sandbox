#!/bin/bash
set -e

# Git config
git config --global --add safe.directory '*'
git config --global user.name "Laeryn Evans"
git config --global user.email "me@laeryn.com"

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

exec claude --dangerously-skip-permissions "$@"
