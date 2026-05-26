---
name: claude-config-sync
description: Use when the user asks to sync Claude Code config, push skills to GitHub, or backup their Claude Code setup to the claude-config-sync repository
---

# Claude Code Config Sync

## Overview

Sync custom Claude Code skills, agents, hooks, and MCP config to the `claude-config-sync` GitHub repo for cross-device portability.

**Sync repo:** `c:\Users\admin\Desktop\claude-config-sync`
**GitHub:** `git@github.com:wuwenjie0307/claude-config-sync.git`

## When to Use

- User says "sync my config", "push my skills", "backup claude config"
- After creating or editing a custom skill
- After adding/updating agents or hooks
- Before switching devices

## What Gets Synced

| Source | Destination in repo |
|---|---|
| `~/.claude/skills/{custom}/` | `skills/{custom}/` |
| `~/.claude/agents/*.md` | Agents (Understand-Anything, skip other built-in) |
| `~/.claude/hooks/hooks.json` | `config/hooks.json` |
| `~/.claude/mcp.json` | `config/mcp.json` |

**Custom skills to sync:** `obsidian`, `mysql-query`, `claude-config-sync`

**Do NOT sync built-in skills:** `brainstorming`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`, `writing-skills`

**Do NOT sync plugin skills** (reinstalled via marketplace): `understand`, `understand-chat`, `understand-dashboard`, `understand-diff`, `understand-domain`, `understand-explain`, `understand-knowledge`, `understand-onboard`

## Sync Workflow

### Step 1 — Copy custom skills to repo

```bash
for skill in obsidian mysql-query claude-config-sync; do
  rm -rf "$REPO/skills/$skill"
  cp -r "$HOME/.claude/skills/$skill" "$REPO/skills/$skill"
done
```

### Step 2 — Copy config files

```bash
cp "$HOME/.claude/hooks/hooks.json" "$REPO/config/hooks.json"
[ -f "$HOME/.claude/mcp.json" ] && cp "$HOME/.claude/mcp.json" "$REPO/config/mcp.json"
```

### Step 3 — Commit and push

```bash
cd "$REPO" && git add -A && git diff --cached --quiet && echo "No changes" || git commit -m "sync: $(date +%Y-%m-%d)" && git push
```

### Step 4 — Update Obsidian vault

Record this sync operation in the Obsidian vault under `projects/claude-config-sync/changelog/`.

## Quick Reference

| Trigger | Action |
|---|---|
| "sync config" / "备份配置" | Run full sync workflow (copy → commit → push) |
| "push skills" | Copy skills only, then commit + push |
| "what's in my sync repo?" | Print current repo status and file listing |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Syncing built-in skills | Only sync the 3 custom skills listed above |
| Syncing Understand-Anything skills | Those are plugin skills, skip them |
| Forgetting to push after commit | Always `git push` after commit |
| Not updating README when adding new custom skill | Update the README skill list and the custom skills list in this file |
| Sync path pointing to wrong repo | Always verify `$REPO` = `c:\Users\admin\Desktop\claude-config-sync` |
