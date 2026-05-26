#!/usr/bin/env bash
# Claude Code Config Sync — macOS/Linux Installer
# Run: bash install.sh [--force] [--skip-mcp] [--vault-path /path/to/vault]
set -euo pipefail

FORCE=false
SKIP_MCP=false
VAULT_PATH=""
GITHUB_USER=""

# ── Parse arguments ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)         FORCE=true; shift ;;
    --skip-mcp)      SKIP_MCP=true; shift ;;
    --vault-path)    VAULT_PATH="$2"; shift 2 ;;
    --github-user)   GITHUB_USER="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Paths ────────────────────────────────────────────────────────────────
CLAUDE_DIR="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
BACKUP_DIR="${CLAUDE_DIR}/backups/$(date +%Y%m%d-%H%M%S)"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_SKILLS="${REPO_DIR}/skills"
MANIFEST="${REPO_DIR}/config/mcp-manifest.txt"

# ── Detect ───────────────────────────────────────────────────────────────
if [ -z "$VAULT_PATH" ]; then
  case "$(uname -s)" in
    Darwin)  VAULT_PATH="${HOME}/Documents/Obsidian" ;;
    *)       VAULT_PATH="${HOME}/Obsidian" ;;
  esac
fi

if [ -z "$GITHUB_USER" ]; then
  GITHUB_USER=$(git config --global user.name 2>/dev/null || echo "")
  if [ -z "$GITHUB_USER" ]; then
    read -r -p "Enter your GitHub username: " GITHUB_USER
  fi
fi

echo ""
echo -e "\033[36m========================================\033[0m"
echo -e "\033[36m  Claude Code Config Sync Installer\033[0m"
echo -e "\033[36m========================================\033[0m"
echo -e "  Vault:       \033[90m${VAULT_PATH}\033[0m"
echo -e "  GitHub:      \033[90m${GITHUB_USER}\033[0m"
echo -e "  Backup:      \033[90m${BACKUP_DIR}\033[0m"
echo -e "\033[36m========================================\033[0m"
echo ""

# ── Built-in skills to skip ──────────────────────────────────────────────
read -r -d '' BUILTIN_SKILLS << 'EOF'
brainstorming
dispatching-parallel-agents
executing-plans
finishing-a-development-branch
receiving-code-review
requesting-code-review
subagent-driven-development
systematic-debugging
test-driven-development
using-git-worktrees
using-superpowers
verification-before-completion
writing-plans
writing-skills
EOF

is_builtin() {
  echo "$BUILTIN_SKILLS" | grep -qxF "$1"
}

# ── Helper: placeholder substitution ─────────────────────────────────────
substitute_placeholders() {
  local file="$1"
  [ ! -f "$file" ] && return
  local changed=false
  if grep -q '{{VAULT_PATH}}' "$file" 2>/dev/null; then
    sed -i.bak "s|{{VAULT_PATH}}|${VAULT_PATH}|g" "$file" && rm -f "${file}.bak"
    changed=true
  fi
  if grep -q '{{GITHUB_USER}}' "$file" 2>/dev/null; then
    sed -i.bak "s|{{GITHUB_USER}}|${GITHUB_USER}|g" "$file" && rm -f "${file}.bak"
    changed=true
  fi
  if grep -q '{{REPO_PATH}}' "$file" 2>/dev/null; then
    sed -i.bak "s|{{REPO_PATH}}|${REPO_DIR}|g" "$file" && rm -f "${file}.bak"
    changed=true
  fi
}

# ── Helper: backup before overwrite ──────────────────────────────────────
backup_and_copy() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    local rel="${dst#${CLAUDE_DIR}/}"
    mkdir -p "$(dirname "${BACKUP_DIR}/${rel}")"
    cp -r "$dst" "${BACKUP_DIR}/${rel}"
    echo "    (backed up existing)"
  fi
  mkdir -p "$(dirname "$dst")"
  cp -r "$src" "$dst"
}

# ── 1. Create directories ────────────────────────────────────────────────
echo -e "\033[33m[1/5] Preparing directories...\033[0m"
mkdir -p "$SKILLS_DIR" "$HOOKS_DIR" "$BACKUP_DIR"

# ── 2. Install custom skills ─────────────────────────────────────────────
echo -e "\033[33m[2/5] Installing custom skills...\033[0m"
if [ -d "$REPO_SKILLS" ]; then
  for skill_dir in "$REPO_SKILLS"/*/; do
    [ ! -d "$skill_dir" ] && continue
    skill_name=$(basename "$skill_dir")

    if is_builtin "$skill_name"; then
      echo -e "  \033[90m- $skill_name (skipped: built-in)\033[0m"
      continue
    fi

    if [[ "$skill_name" == understand* ]]; then
      echo -e "  \033[90m- $skill_name (skipped: install via marketplace)\033[0m"
      continue
    fi

    dst="${SKILLS_DIR}/${skill_name}"
    backup_and_copy "$skill_dir" "$dst"

    # Substitute placeholders
    local skill_file="${dst}/SKILL.md"
    [ -f "$skill_file" ] && substitute_placeholders "$skill_file"

    echo -e "  \033[32m+ $skill_name\033[0m"
  done
fi

# ── 3. Install hooks ─────────────────────────────────────────────────────
echo -e "\033[33m[3/5] Installing hooks config...\033[0m"
hooks_src="${REPO_DIR}/config/hooks.json"
if [ -f "$hooks_src" ]; then
  hooks_dst="${HOOKS_DIR}/hooks.json"
  backup_and_copy "$hooks_src" "$hooks_dst"
  echo -e "  \033[32m+ hooks.json\033[0m"
fi

# ── 4. MCP servers (from manifest) ───────────────────────────────────────
echo -e "\033[33m[4/5] Installing MCP servers...\033[0m"
if [ "$SKIP_MCP" = false ] && [ -f "$MANIFEST" ]; then
  while IFS= read -r line; do
    line=$(echo "$line" | xargs)  # trim
    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue
    echo -e "  Pre-fetching \033[90m${line}\033[0m..."
    if npx -y "$line" --version 2>/dev/null; then
      echo -e "  \033[32m+ $line\033[0m"
    else
      echo -e "  \033[33m! $line (install failed, will retry on first use)\033[0m"
    fi
  done < "$MANIFEST"
fi

# Copy mcp.json template (never overwrite existing)
mcp_src="${REPO_DIR}/config/mcp.json"
if [ ! -f "${CLAUDE_DIR}/mcp.json" ] && [ -f "$mcp_src" ]; then
  cp "$mcp_src" "${CLAUDE_DIR}/mcp.json"
  echo -e "  \033[33m+ mcp.json (template — edit API keys!)\033[0m"
elif [ -f "${CLAUDE_DIR}/mcp.json" ]; then
  echo -e "  \033[90m- mcp.json (existing preserved)\033[0m"
fi

# ── 5. Summary ───────────────────────────────────────────────────────────
echo -e "\033[33m[5/5] Done!\033[0m"
echo ""
echo -e "\033[36m──────────────────────────────────────────\033[0m"
echo -e "  \033[32mInstall complete!\033[0m"
echo -e "  Backup saved to: \033[90m${BACKUP_DIR}\033[0m"
echo ""
echo "  Next steps:"
echo "  1. Edit  ~/.claude/mcp.json  (set API keys)"
echo "  2. Edit  ~/.claude/settings.json  (set model keys)"
echo "  3. In Claude Code, run:"
echo -e "     \033[36m/plugin marketplace add Lum1104/Understand-Anything\033[0m"
echo -e "     \033[36m/plugin install understand-anything\033[0m"
echo "  4. Restart Claude Code"
echo -e "\033[36m──────────────────────────────────────────\033[0m"
echo ""

# ── Write install metadata ───────────────────────────────────────────────
cat > "${CLAUDE_DIR}/.sync-meta.yml" << METAEOF
# Installed by claude-config-sync
install_date: $(date '+%Y-%m-%d %H:%M:%S')
vault_path: ${VAULT_PATH}
github_user: ${GITHUB_USER}
repo_path: ${REPO_DIR}
METAEOF
