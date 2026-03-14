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
    Remove the entire ~/.claude directory before deploying (DANGEROUS).
    By default, only agents/ and projects/ are removed.

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
$ProjectsDst = Join-Path $ClaudeDir "projects"
$SkillsSrc  = Join-Path $RepoDir "skills"
$SkillsDst  = Join-Path $ClaudeDir "skills"

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

# --- 2. Sanitize ---
Write-Banner "Sanitizing Workspace"

if ($ForceWipe) {
    Write-Warn "Full wipe: removing entire $ClaudeDir"
    if (Test-Path $ClaudeDir) { Remove-Item $ClaudeDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
    Write-Ok "Fresh directory created: $ClaudeDir"
} else {
    Write-Info "Removing old agents/ and projects/ directories"
    if (Test-Path $AgentsDst)   { Remove-Item $AgentsDst -Recurse -Force }
    if (Test-Path $ProjectsDst) { Remove-Item $ProjectsDst -Recurse -Force }
    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
    }
    Write-Ok "Workspace clean"
}

# --- 3. Deploy Agents ---
Write-Banner "Deploying Agents"

if (-not (Test-Path $AgentsSrc)) {
    Write-Error "Agents source not found at $AgentsSrc"
    exit 1
}

Write-Info "Copying agents to $AgentsDst"
Copy-Item -Path $AgentsSrc -Destination $AgentsDst -Recurse -Force
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

# --- 5. Semgrep Check ---
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

# --- 6. Validate ---
Write-Banner "Validating Installation"

$failed = $false

# Canonical orchestrator
$orchestrator = Join-Path (Join-Path $AgentsDst "07_Orchestrators") "Tech_Lead_Orchestrator.md"
if (Test-Path $orchestrator) {
    Write-Ok "Tech Lead Orchestrator present (canonical)"
} else {
    Write-Warn "Missing: Tech Lead Orchestrator at $orchestrator"
    $failed = $true
}

# No deprecated orchestrator
$deprecated = Get-ChildItem -Path $AgentsDst -Recurse -Filter "*.md" | Select-String -Pattern "tech-lead-orchestrator-deprecated" -ErrorAction SilentlyContinue
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

# --- Done ---
Write-Banner "Installation Complete"
Write-Host ""
Write-Info "Agents deployed to: $AgentsDst"
Write-Info "Skills deployed to: $SkillsDst"
Write-Host ""
Write-Info "Works with both Claude Code CLI and VS Code extension."
Write-Info "Run 'claude doctor' to verify your Claude Code installation."
Write-Host ""
