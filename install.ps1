# Claude Code Config Sync — Windows Installer
# Run: powershell -ExecutionPolicy Bypass -File install.ps1
# Or:   iwr -useb <raw-url>/install.ps1 | iex

$ErrorActionPreference = "Stop"
$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$SKILLS_DIR = "$CLAUDE_DIR\skills"
$AGENTS_DIR = "$CLAUDE_DIR\agents"
$HOOKS_DIR = "$CLAUDE_DIR\hooks"

Write-Host "==> Claude Code Config Sync ==" -ForegroundColor Cyan
Write-Host ""

# ── 1. Create directories ──────────────────────────────────────────
Write-Host "[1/5] Creating directories..." -ForegroundColor Yellow
foreach ($dir in @($SKILLS_DIR, $AGENTS_DIR, $HOOKS_DIR)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

# ── 2. Install custom skills ───────────────────────────────────────
Write-Host "[2/5] Installing custom skills..." -ForegroundColor Yellow
$REPO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $REPO_DIR) { $REPO_DIR = Get-Location }
$REPO_SKILLS = "$REPO_DIR\skills"

if (Test-Path $REPO_SKILLS) {
    Get-ChildItem -Directory "$REPO_SKILLS\*" | ForEach-Object {
        $dst = "$SKILLS_DIR\$($_.Name)"
        Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
        Write-Host "  + $($_.Name)" -ForegroundColor Green
    }
}

# ── 3. Install hooks ───────────────────────────────────────────────
Write-Host "[3/5] Installing hooks config..." -ForegroundColor Yellow
if (Test-Path "$REPO_DIR\config\hooks.json") {
    Copy-Item -Path "$REPO_DIR\config\hooks.json" -Destination "$HOOKS_DIR\hooks.json" -Force
    Write-Host "  + hooks.json" -ForegroundColor Green
}

# ── 4. MCP servers (install via npm) ───────────────────────────────
Write-Host "[4/5] Installing MCP servers..." -ForegroundColor Yellow
$mcpJson = "$REPO_DIR\config\mcp.json"
if (Test-Path $mcpJson) {
    $mcp = Get-Content $mcpJson | ConvertFrom-Json
    foreach ($server in $mcp.mcpServers.PSObject.Properties) {
        $cmd = $server.Value.command
        $args = $server.Value.args
        if ($cmd -eq "npx" -and $args[0] -eq "-y") {
            $pkg = $args[1]
            Write-Host "  Installing $pkg..." -ForegroundColor Gray
            npx -y $pkg --version 2>$null
            Write-Host "  + $($server.Name) ($pkg)" -ForegroundColor Green
        }
    }
}

# Copy mcp.json template if not exists
if (-not (Test-Path "$CLAUDE_DIR\mcp.json") -and (Test-Path $mcpJson)) {
    Copy-Item -Path $mcpJson -Destination "$CLAUDE_DIR\mcp.json"
    Write-Host "  + mcp.json (template — edit API keys!)" -ForegroundColor Yellow
}

# ── 5. Plugins to install in Claude Code ───────────────────────────
Write-Host "[5/5] Plugins to install manually in Claude Code:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Run these INSIDE Claude Code:" -ForegroundColor White
Write-Host "  /plugin marketplace add Lum1104/Understand-Anything" -ForegroundColor Cyan
Write-Host "  /plugin install understand-anything" -ForegroundColor Cyan
Write-Host ""
Write-Host "==> Done! Restart Claude Code to load everything." -ForegroundColor Cyan
