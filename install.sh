#!/usr/bin/env bash
# Claude Code Config Sync — macOS/Linux Installer
# Run: bash install.sh
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
AGENTS_DIR="$CLAUDE_DIR/agents"
HOOKS_DIR="$CLAUDE_DIR/hooks"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_SKILLS="$REPO_DIR/skills"

echo -e "\033[36m==> Claude Code Config Sync ==\033[0m"
echo ""

# ── 1. Create directories ──────────────────────────────────────────
echo -e "\033[33m[1/5] Creating directories...\033[0m"
mkdir -p "$SKILLS_DIR" "$AGENTS_DIR" "$HOOKS_DIR"

# ── 2. Install custom skills ───────────────────────────────────────
echo -e "\033[33m[2/5] Installing custom skills...\033[0m"
if [ -d "$REPO_SKILLS" ]; then
  for skill_dir in "$REPO_SKILLS"/*/; do
    skill_name=$(basename "$skill_dir")
    cp -r "$skill_dir" "$SKILLS_DIR/"
    echo -e "  \033[32m+ $skill_name\033[0m"
  done
fi

# ── 3. Install hooks ───────────────────────────────────────────────
echo -e "\033[33m[3/5] Installing hooks config...\033[0m"
if [ -f "$REPO_DIR/config/hooks.json" ]; then
  cp "$REPO_DIR/config/hooks.json" "$HOOKS_DIR/hooks.json"
  echo -e "  \033[32m+ hooks.json\033[0m"
fi

# ── 4. MCP servers ─────────────────────────────────────────────────
echo -e "\033[33m[4/5] Installing MCP servers...\033[0m"
if [ -f "$REPO_DIR/config/mcp.json" ]; then
  for pkg in $(grep -oP '"npx".*"-y".*"\K[^"]+' "$REPO_DIR/config/mcp.json" | head -5); do
    echo "  Installing $pkg..."
    npx -y "$pkg" --version 2>/dev/null || true
    echo -e "  \033[32m+ $pkg\033[0m"
  done

  if [ ! -f "$CLAUDE_DIR/mcp.json" ]; then
    cp "$REPO_DIR/config/mcp.json" "$CLAUDE_DIR/mcp.json"
    echo -e "  \033[33m+ mcp.json (template — edit API keys!)\033[0m"
  fi
fi

# ── 5. Plugins to install ──────────────────────────────────────────
echo -e "\033[33m[5/5] Plugins to install manually in Claude Code:\033[0m"
echo ""
echo "  Run these INSIDE Claude Code:"
echo -e "  \033[36m/plugin marketplace add Lum1104/Understand-Anything\033[0m"
echo -e "  \033[36m/plugin install understand-anything\033[0m"
echo ""
echo -e "\033[36m==> Done! Restart Claude Code to load everything.\033[0m"
