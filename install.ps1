<#
.SYNOPSIS
Claude Code Config Sync — Windows Installer
.DESCRIPTION
Installs custom skills, hooks, MCP servers from claude-config-sync repo.
Creates a backup before overwriting any existing config.
.PARAMETER Force
Overwrite configs without prompting
.PARAMETER SkipMCP
Skip MCP package installation
.PARAMETER VaultPath
Path to Obsidian vault (default: ~/Desktop/Obsidian)
.EXAMPLE
powershell -ExecutionPolicy Bypass -File install.ps1
powershell -ExecutionPolicy Bypass -File install.ps1 -VaultPath "D:\MyVault"
#>
param(
    [switch]$Force,
    [switch]$SkipMCP,
    [string]$VaultPath = ""
)

$ErrorActionPreference = "Stop"

# ── Paths ───────────────────────────────────────────────────────────────
$CLAUDE_DIR   = "$env:USERPROFILE\.claude"
$SKILLS_DIR   = "$CLAUDE_DIR\skills"
$HOOKS_DIR    = "$CLAUDE_DIR\hooks"
$BACKUP_DIR   = "$CLAUDE_DIR\backups\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$REPO_DIR     = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$REPO_SKILLS  = "$REPO_DIR\skills"
$MANIFEST     = "$REPO_DIR\config\mcp-manifest.txt"

# ── Default vault path ──────────────────────────────────────────────────
if (-not $VaultPath) {
    $VaultPath = "$env:USERPROFILE\Desktop\Obsidian"
}

# ── Detect GitHub user ───────────────────────────────────────────────────
$GITHUB_USER = ""
try { $GITHUB_USER = (git config user.name 2>$null).Trim() } catch { }
if (-not $GITHUB_USER) {
    try { $GITHUB_USER = (git config --global user.name 2>$null).Trim() } catch { }
}
if (-not $GITHUB_USER) {
    [Console]::Write("Enter your GitHub username: ")
    $GITHUB_USER = [Console]::ReadLine()
}
# Fallback for non-interactive: try to infer from git remote
if (-not $GITHUB_USER) {
    try {
        $remote = (git -C "$REPO_DIR" remote get-url origin 2>$null)
        if ($remote -match 'github\.com[:/]([^/]+)/') { $GITHUB_USER = $matches[1] }
    } catch { }
}
if (-not $GITHUB_USER) {
    Write-Host "  WARNING: Could not detect GitHub username. Skill placeholders will use default." -ForegroundColor Yellow
    $GITHUB_USER = "YOUR_GITHUB_USERNAME"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Config Sync Installer"     -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Vault:       $VaultPath"              -ForegroundColor Gray
Write-Host "  GitHub:      $GITHUB_USER"            -ForegroundColor Gray
Write-Host "  Backup:      $BACKUP_DIR"             -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Helper: placeholder substitution ─────────────────────────────────────
function Invoke-PlaceholderSub {
    param([string]$FilePath, [string]$Vault, [string]$User, [string]$Repo)
    if (-not (Test-Path $FilePath)) { return }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $changed = $false
    if ($content -match '\{\{VAULT_PATH\}\}') {
        $content = $content -replace '\{\{VAULT_PATH\}\}', $Vault
        $changed = $true
    }
    if ($content -match '\{\{GITHUB_USER\}\}') {
        $content = $content -replace '\{\{GITHUB_USER\}\}', $User
        $changed = $true
    }
    if ($content -match '\{\{REPO_PATH\}\}') {
        $content = $content -replace '\{\{REPO_PATH\}\}', $Repo
        $changed = $true
    }
    if ($changed) {
        Set-Content $FilePath -Value $content -Encoding UTF8 -NoNewline
    }
}

# ── Helper: backup before overwrite ──────────────────────────────────────
function Backup-And-Copy {
    param([string]$Source, [string]$Destination)
    if (Test-Path $Destination) {
        $parent = Split-Path $Destination -Parent
        $backupDest = "$BACKUP_DIR\$($Destination.Substring($CLAUDE_DIR.Length).TrimStart('\/'))"
        New-Item -ItemType Directory -Force -Path (Split-Path $backupDest -Parent) | Out-Null
        Copy-Item -Path $Destination -Destination $backupDest -Recurse -Force
        Write-Host "    (backed up existing)" -ForegroundColor DarkGray
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
    Copy-Item -Path $Source -Destination $Destination -Recurse -Force
}

# ── 1. Create directories + backup ───────────────────────────────────────
Write-Host "[1/5] Preparing directories..." -ForegroundColor Yellow
foreach ($dir in @($SKILLS_DIR, $HOOKS_DIR, $BACKUP_DIR)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# ── 2. Install custom skills (with placeholder substitution) ─────────────
Write-Host "[2/5] Installing custom skills..." -ForegroundColor Yellow
if (Test-Path $REPO_SKILLS) {
    # Built-in skills to NEVER overwrite
    $BUILTIN = @('brainstorming','dispatching-parallel-agents','executing-plans',
        'finishing-a-development-branch','receiving-code-review','requesting-code-review',
        'subagent-driven-development','systematic-debugging','test-driven-development',
        'using-git-worktrees','using-superpowers','verification-before-completion',
        'writing-plans','writing-skills')

    $skillDirs = @(Get-ChildItem -LiteralPath $REPO_SKILLS -Directory -ErrorAction SilentlyContinue)
    foreach ($skillDir in $skillDirs) {
        $skillName = $skillDir.Name
        if ($skillName -in $BUILTIN) {
            Write-Host "  - $skillName (skipped: built-in)" -ForegroundColor DarkGray
            continue
        }
        # Skip plugin skills (understand-*)
        if ($skillName -like 'understand*') {
            Write-Host "  - $skillName (skipped: install via marketplace)" -ForegroundColor DarkGray
            continue
        }

        $dst = "$SKILLS_DIR\$skillName"
        Backup-And-Copy -Source $skillDir.FullName -Destination $dst

        # Substitute placeholders in SKILL.md
        $skillFile = Join-Path $dst "SKILL.md"
        if (Test-Path $skillFile) {
            Invoke-PlaceholderSub -FilePath $skillFile -Vault $VaultPath -User $GITHUB_USER -Repo $REPO_DIR
        }

        Write-Host "  + $skillName" -ForegroundColor Green
    }
}

# ── 3. Install hooks ─────────────────────────────────────────────────────
Write-Host "[3/5] Installing hooks config..." -ForegroundColor Yellow
$hooksSrc = "$REPO_DIR\config\hooks.json"
if (Test-Path $hooksSrc) {
    $hooksDst = "$HOOKS_DIR\hooks.json"
    Backup-And-Copy -Source $hooksSrc -Destination $hooksDst
    Write-Host "  + hooks.json" -ForegroundColor Green
}

# ── 4. MCP servers (from manifest) ───────────────────────────────────────
Write-Host "[4/5] Installing MCP servers..." -ForegroundColor Yellow
if (-not $SkipMCP -and (Test-Path $MANIFEST)) {
    Get-Content $MANIFEST | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#')) {
            Write-Host "  Pre-fetching $line..." -ForegroundColor Gray
            try {
                npx -y $line --version 2>$null | Out-Null
                Write-Host "  + $line" -ForegroundColor Green
            } catch {
                Write-Host "  ! $line (install failed, will retry on first use)" -ForegroundColor DarkYellow
            }
        }
    }
}

# Copy mcp.json template (never overwrite existing)
$mcpSrc = "$REPO_DIR\config\mcp.json"
if (-not (Test-Path "$CLAUDE_DIR\mcp.json") -and (Test-Path $mcpSrc)) {
    Copy-Item -Path $mcpSrc -Destination "$CLAUDE_DIR\mcp.json"
    Write-Host "  + mcp.json (template — edit API keys!)" -ForegroundColor Yellow
} elseif (Test-Path "$CLAUDE_DIR\mcp.json") {
    Write-Host "  - mcp.json (existing preserved)" -ForegroundColor DarkGray
}

# ── 5. Summary ───────────────────────────────────────────────────────────
Write-Host "[5/5] Done!" -ForegroundColor Yellow
Write-Host ""
Write-Host "──────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  Install complete!" -ForegroundColor Green
Write-Host "  Backup saved to: $BACKUP_DIR" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Edit  ~/.claude/mcp.json  (set API keys)" -ForegroundColor White
Write-Host "  2. Edit  ~/.claude/settings.json  (set model keys)" -ForegroundColor White
Write-Host "  3. In Claude Code, run:" -ForegroundColor White
Write-Host "     /plugin marketplace add Lum1104/Understand-Anything" -ForegroundColor Cyan
Write-Host "     /plugin install understand-anything" -ForegroundColor Cyan
Write-Host "  4. Restart Claude Code" -ForegroundColor White
Write-Host "──────────────────────────────────────────" -ForegroundColor Cyan
Write-Host ""

# ── Write install metadata ───────────────────────────────────────────────
@"
# Installed by claude-config-sync
install_date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
vault_path: $VaultPath
github_user: $GITHUB_USER
repo_path: $REPO_DIR
"@ | Out-File -FilePath "$CLAUDE_DIR\.sync-meta.yml" -Encoding UTF8
