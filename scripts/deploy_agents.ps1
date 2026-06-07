<#
.SYNOPSIS
    Nation of Elites - Agents Deployment Script for Windows

.DESCRIPTION
    End-to-end: clone/pull > sanitize > deploy > validate
    Windows-native equivalent of deploy_agents.sh

.PARAMETER RepoUrl
    Git repository URL. Default: https://github.com/advisely/claude-code-agents-team-nation-of-elites.git

.PARAMETER RepoDir
    Local cache directory for the cloned repo. Default: $env:TEMP\nation-of-elites

.PARAMETER ForceWipe
    Force-refresh deployed content: removes only ~/.claude/agents and
    ~/.claude/skills before redeploying. Never touches projects/ (Claude Code
    memory + session transcripts), settings.json, or credentials.
    The default deploy is non-destructive and mirrors agents/ in place.

.EXAMPLE
    .\deploy_agents.ps1
    .\deploy_agents.ps1 -ForceWipe
    .\deploy_agents.ps1 -RepoUrl "https://github.com/myorg/my-fork.git"
#>

param(
    [string]$RepoUrl = "https://github.com/advisely/claude-code-agents-team-nation-of-elites.git",
    [string]$RepoDir = (Join-Path $env:TEMP "nation-of-elites"),
    [switch]$ForceWipe
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$ClaudeDir  = Join-Path $env:USERPROFILE ".claude"
$AgentsSrc  = Join-Path $RepoDir "agents"
$AgentsDst  = Join-Path $ClaudeDir "agents"
$SkillsSrc  = Join-Path $RepoDir "skills"
$SkillsDst  = Join-Path $ClaudeDir "skills"
# Note: ~/.claude/projects (memory + session transcripts) is intentionally NOT
# referenced — the deploy never touches user data.

# --- Helpers ---
function Write-Banner($Title) {
    $line = [string]::new([char]0x2501, 68)
    Write-Host ""
    Write-Host "  $([char]0x250F)$line$([char]0x2513)" -ForegroundColor Magenta
    Write-Host "  $([char]0x2503) $Title" -ForegroundColor Magenta
    Write-Host "  $([char]0x2517)$line$([char]0x251B)" -ForegroundColor Magenta
}

function Write-Info($Message) {
    Write-Host "  > $Message" -ForegroundColor Cyan
}

function Write-Ok($Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Warn($Message) {
    Write-Host "  [!!] $Message" -ForegroundColor Yellow
}

# --- Pre-flight ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is required. Install from https://git-scm.com/downloads/win"
    exit 1
}

# --- 1. Clone or Update ---
Write-Banner "Syncing Repository"

if (Test-Path (Join-Path $RepoDir ".git")) {
    Write-Info "Updating existing clone at $RepoDir"
    git -C $RepoDir fetch --all --prune 2>$null
    git -C $RepoDir pull --ff-only
} else {
    Write-Info "Cloning into $RepoDir"
    git clone $RepoUrl $RepoDir
}
Write-Ok "Repository synced"

# --- 2. Sanitize (data-safe) ---
Write-Banner "Sanitizing Workspace (data-safe)"

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
}

if ($ForceWipe) {
    Write-Warn "Force refresh: clearing deployed content only (agents/ + skills/)"
    Write-Info "Preserving projects/ (memory + session history), settings.json, and credentials"
    if (Test-Path $AgentsDst) { Remove-Item $AgentsDst -Recurse -Force }
    if (Test-Path $SkillsDst) { Remove-Item $SkillsDst -Recurse -Force }
    Write-Ok "Deployed content cleared - user data untouched"
} else {
    Write-Info "Non-destructive deploy: agents/ mirrored in place; projects/ & settings preserved"
    Write-Ok "No destructive cleanup needed"
}

# --- 3. Deploy Agents ---
Write-Banner "Deploying Agents"

if (-not (Test-Path $AgentsSrc)) {
    Write-Error "Agents source not found at $AgentsSrc"
    exit 1
}

Write-Info "Mirroring agents to $AgentsDst (purges stale agents, like rsync --delete)"
# robocopy /MIR mirrors src CONTENTS into dest and removes extras in dest.
# Purge is scoped to the agents/ folder only — projects/ and settings are never in scope.
robocopy $AgentsSrc $AgentsDst /MIR /NJH /NJS /NDL /NP /NFL | Out-Null
# robocopy exit codes 0-7 are success (8+ = failure); reset so later logic isn't confused.
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy failed mirroring agents (code $LASTEXITCODE)"; exit 1 }
$global:LASTEXITCODE = 0
Write-Ok "Agents deployed"

# --- 4. Deploy Skills ---
Write-Banner "Deploying Skills"

if (Test-Path $SkillsSrc) {
    Write-Info "Installing custom Nation of Elites skills"
    if (-not (Test-Path $SkillsDst)) {
        New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null
    }
    Copy-Item -Path (Join-Path $SkillsSrc "*") -Destination $SkillsDst -Recurse -Force
    Write-Ok "Custom skills installed"
} else {
    Write-Info "No custom skills found (optional)"
}

# Install Anthropic official skills if not already present
$pdfSkill = Join-Path $SkillsDst "pdf"
$docxSkill = Join-Path $SkillsDst "docx"
if (-not (Test-Path $pdfSkill) -and -not (Test-Path $docxSkill)) {
    Write-Info "Installing Anthropic official skills..."
    $tempSkills = Join-Path $env:TEMP "anthropic-skills-$PID"
    try {
        git clone --depth 1 https://github.com/anthropics/skills.git $tempSkills 2>$null
        if (-not (Test-Path $SkillsDst)) {
            New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null
        }

        # Document skills
        $docSkills = Join-Path $tempSkills "document-skills"
        if (Test-Path $docSkills) {
            Copy-Item -Path (Join-Path $docSkills "*") -Destination $SkillsDst -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Other useful skills
        foreach ($skill in @("mcp-builder", "webapp-testing", "skill-creator", "artifacts-builder", "canvas-design")) {
            $skillPath = Join-Path $tempSkills $skill
            if (Test-Path $skillPath) {
                Copy-Item -Path $skillPath -Destination (Join-Path $SkillsDst $skill) -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Ok "Anthropic skills installed"
    } catch {
        Write-Warn "Failed to clone Anthropic skills (network issue?). Skipping."
        Write-Info "Install manually later: git clone https://github.com/anthropics/skills.git $SkillsDst"
    } finally {
        if (Test-Path $tempSkills) { Remove-Item $tempSkills -Recurse -Force -ErrorAction SilentlyContinue }
    }
} else {
    Write-Ok "Anthropic skills already installed (skipping)"
}

# --- 5. Official Plugins ---
Write-Banner "Official Plugins - Autoconfiguration"

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeCmd) {
    Write-Info "Detecting available official Anthropic plugins..."
    Write-Info "These plugins connect your agents to external services via MCP."
    Write-Host ""

    # Names below are the actual official plugin ids in claude-plugins-official.
    # Note: Jira AND Confluence ship together in the single "atlassian" plugin.
    $plugins = @(
        @{ Name = "github";    Desc = "GitHub (issues, PRs, code search, actions)" },
        @{ Name = "gitlab";    Desc = "GitLab (issues, MRs, pipelines)" },
        @{ Name = "slack";     Desc = "Slack (messaging, channels, notifications)" },
        @{ Name = "atlassian"; Desc = "Atlassian - Jira & Confluence (tickets, sprints, wiki)" },
        @{ Name = "linear";    Desc = "Linear (issues, projects, cycles)" },
        @{ Name = "figma";     Desc = "Figma (design files, components)" },
        @{ Name = "sentry";    Desc = "Sentry (error tracking, performance)" },
        @{ Name = "vercel";    Desc = "Vercel (deployments, preview URLs)" },
        @{ Name = "firebase";  Desc = "Firebase (auth, Firestore, hosting)" },
        @{ Name = "supabase";  Desc = "Supabase (Postgres, auth, storage)" },
        @{ Name = "notion";    Desc = "Notion (docs, databases, wikis)" },
        @{ Name = "asana";     Desc = "Asana (tasks, timelines, portfolios)" }
    )

    Write-Host "  Available plugins:" -ForegroundColor White
    foreach ($p in $plugins) {
        Write-Host ("    {0,-14} {1}" -f $p.Name, $p.Desc) -ForegroundColor Cyan
    }
    Write-Host ""

    if ([Environment]::UserInteractive) {
        $answer = Read-Host "  Install official plugins interactively? [y/N]"
        if ($answer -match '^[yY]') {
            $installed = 0
            foreach ($p in $plugins) {
                $ans = Read-Host "    Install $($p.Name) ($($p.Desc))? [y/N]"
                if ($ans -match '^[yY]') {
                    Write-Info "Run in Claude Code: /plugin install $($p.Name)@claude-plugins-official"
                    $installed++
                }
            }
            if ($installed -gt 0) {
                Write-Ok "$installed plugin(s) selected. Run the /plugin install commands in Claude Code."
            } else {
                Write-Info "No plugins selected."
            }
        } else {
            Write-Info "Skipping. Install later: /plugin install <name>@claude-plugins-official"
        }
    } else {
        Write-Info "Non-interactive mode. Install plugins in Claude Code: /plugin install <name>@claude-plugins-official"
    }
} else {
    Write-Warn "Claude Code CLI not found. Skipping plugin autoconfiguration."
    Write-Info "Install Claude Code first, then re-run to configure plugins."
}

# --- 6. Semgrep Check ---
Write-Banner "Semgrep SAST Check"

$semgrepCmd = Get-Command semgrep -ErrorAction SilentlyContinue
if ($semgrepCmd) {
    $sgVersion = & semgrep --version 2>$null
    Write-Ok "Semgrep installed: v$sgVersion"

    # Check for Semgrep token
    $semgrepSettings = Join-Path (Join-Path $env:USERPROFILE ".semgrep") "settings.yml"
    if (Test-Path $semgrepSettings) {
        Write-Ok "Semgrep token configured ($semgrepSettings)"
    } else {
        Write-Warn "Semgrep token not found. Run 'semgrep login' to authenticate for full rule access."
    }
} else {
    Write-Warn "Semgrep not installed. Install with: pip install semgrep"
    Write-Info "Semgrep SAST skill is deployed but CLI scanning requires the semgrep binary."
    Write-Info "The Semgrep MCP plugin (if enabled in Claude Code) works independently."
}

# --- 7. Validate ---
Write-Banner "Validating Installation"

$failed = $false

# Canonical orchestrator
$orchestrator = Join-Path (Join-Path $AgentsDst "07_Orchestrators") "Chief_Operations_Orchestrator.md"
if (Test-Path $orchestrator) {
    Write-Ok "Chief Operations Orchestrator present (canonical)"
} else {
    Write-Warn "Missing: Chief Operations Orchestrator at $orchestrator"
    $failed = $true
}

# No deprecated orchestrator
$deprecated = Get-ChildItem -Path $AgentsDst -Recurse -Filter "*.md" | Select-String -Pattern "chief-operations-orchestrator-deprecated" -ErrorAction SilentlyContinue
if ($deprecated) {
    Write-Warn "Found deprecated orchestrator entries"
    $failed = $true
} else {
    Write-Ok "No deprecated orchestrator references found"
}

# Agent count
$agentFiles = Get-ChildItem -Path $AgentsDst -Recurse -Filter "*.md" | Measure-Object
$count = $agentFiles.Count
if ($count -ge 25) {
    Write-Ok "Agent count: $count files deployed"
} else {
    Write-Warn "Low agent count: $count (verify deployment)"
}

# Skills count
if (Test-Path $SkillsDst) {
    $skillFiles = Get-ChildItem -Path $SkillsDst -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | Measure-Object
    $skillCount = $skillFiles.Count
    if ($skillCount -ge 3) {
        Write-Ok "Skills count: $skillCount skills available"
    } else {
        Write-Warn "Low skills count: $skillCount (installation may be incomplete)"
    }
}

# Semgrep SAST skill
$semgrepSkill = Join-Path (Join-Path $SkillsDst "semgrep-sast") "SKILL.md"
if (Test-Path $semgrepSkill) {
    Write-Ok "Semgrep SAST skill deployed"
} else {
    Write-Warn "Semgrep SAST skill not found at $semgrepSkill"
}

# Pipeline skills
$pipelineQuality = Join-Path (Join-Path $SkillsDst "pipeline-quality") "SKILL.md"
$pipelineBuild = Join-Path (Join-Path $SkillsDst "pipeline-full-build") "SKILL.md"
if ((Test-Path $pipelineQuality) -and (Test-Path $pipelineBuild)) {
    Write-Ok "Pipeline skills deployed (quality + full-build)"
} else {
    Write-Warn "Pipeline skills not fully deployed"
}

if ($failed) {
    Write-Error "Validation failed - check warnings above"
    exit 2
}

# --- 8. Done ---
Write-Banner "Installation Complete"
Write-Host ""
Write-Info "Agents deployed to: $AgentsDst"
Write-Info "Skills deployed to: $SkillsDst"
Write-Host ""
Write-Info "Works with both Claude Code CLI and VS Code extension."
Write-Info "Run 'claude doctor' to verify your Claude Code installation."
Write-Host ""
