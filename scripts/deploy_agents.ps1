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
    Force-refresh deployed content: removes only the agents and skills THIS
    deploy previously installed (tracked in ~/.claude/.noe-manifest-*), then
    redeploys. Never touches projects/ (Claude Code memory + session
    transcripts), settings.json, commands/, plugins/, or credentials, and never
    removes agents or skills you authored yourself, nor Anthropic's official
    skills. Every destructive step backs up to ~/.claude/backups first.

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
# Manifests record exactly what this deploy installed, so a later run can purge
# its own stale output without guessing at - or deleting - anything the user put
# there. Kept outside agents/ and skills/ so they are never mirrored away.
$ManifestAgents = Join-Path $ClaudeDir ".noe-manifest-agents"
$ManifestSkills = Join-Path $ClaudeDir ".noe-manifest-skills"
$BackupRoot     = Join-Path $ClaudeDir "backups"
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

# --- Native command helper ---
# With $ErrorActionPreference = "Stop", Windows PowerShell 5.1 turns ANY native
# command's stderr output into a terminating NativeCommandError - even when the
# command succeeded (exit code 0). Tools that write progress or notices to
# stderr (git, semgrep, pip shims) would abort the whole deploy.
#
# Route native calls through this helper: stderr is captured instead of thrown,
# and the exit code becomes the authoritative success signal.
function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$Arguments = @(),
        [switch]$Quiet
    )
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $Exe @Arguments 2>&1
        $code = $LASTEXITCODE
    } catch {
        $output = $_.Exception.Message
        $code = 1
    } finally {
        $ErrorActionPreference = $previous
    }
    if (-not $Quiet -and $output) {
        $output | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
    [pscustomobject]@{
        ExitCode = if ($null -eq $code) { 0 } else { $code }
        Output   = ($output | Out-String).Trim()
    }
}

# A .git directory can exist yet be unusable - an interrupted clone, a corrupted
# index, or a tree copied across filesystems. Test-Path alone is not enough;
# ask git whether it can actually resolve the repository.
function Test-GitRepo($Path) {
    if (-not (Test-Path (Join-Path $Path ".git"))) { return $false }
    return (Invoke-Native git @("-C", $Path, "rev-parse", "--git-dir") -Quiet).ExitCode -eq 0
}

# Guard against a mis-set -RepoDir wiping something important.
function Assert-SafeCachePath($Path) {
    $resolved = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $forbidden = @(
        $env:USERPROFILE, $env:SystemDrive, $env:SystemRoot,
        (Join-Path $env:USERPROFILE ".claude"), $env:TEMP
    ) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\', '/') }
    if ([string]::IsNullOrWhiteSpace($resolved) -or $forbidden -contains $resolved) {
        Write-Error "Refusing to use '$resolved' as the repo cache directory."
        exit 1
    }
    # Anywhere INSIDE ~/.claude is off-limits too, not just ~/.claude itself: the
    # cache gets force-removed when it is corrupt, and a stray -RepoDir pointing
    # at e.g. ~/.claude/projects would take Claude Code memory with it.
    $claudeRoot = (Join-Path $env:USERPROFILE ".claude").TrimEnd('\', '/')
    if ($resolved.StartsWith($claudeRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Error "Refusing to use '$resolved' as the repo cache directory (inside $claudeRoot)."
        exit 1
    }
    return $resolved
}

# Timestamped copy of anything we are about to delete from. Deletion in this
# script is manifest-scoped and should never surprise anyone - but "should
# never" is not a recovery plan, so keep one.
function Backup-Path($Source, $Label) {
    if (-not (Test-Path $Source)) { return }
    if (-not (Test-Path $BackupRoot)) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    }
    $dest = Join-Path $BackupRoot ("{0}-{1}" -f $Label, (Get-Date -Format "yyyyMMdd-HHmmss"))
    try {
        Copy-Item -Path $Source -Destination $dest -Recurse -Force -ErrorAction Stop
        Write-Info "Backup written: $dest"
    } catch {
        Write-Error "Could not back up $Source - aborting rather than deleting unbacked data."
        exit 1
    }
}

# Relative paths of every file under a directory, sorted.
function Get-RelativeFiles($Root) {
    if (-not (Test-Path $Root)) { return @() }
    $full = (Resolve-Path $Root).Path.TrimEnd('\', '/')
    return @(Get-ChildItem -Path $full -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName.Substring($full.Length + 1) } | Sort-Object)
}

# Top-level entry names under a directory, sorted.
function Get-TopLevelNames($Root) {
    if (-not (Test-Path $Root)) { return @() }
    return @(Get-ChildItem -Path $Root -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Name } | Sort-Object)
}

# Windows PowerShell 5.1's `-Encoding UTF8` always emits a BOM, which would ride
# along on the first manifest entry and stop it from ever matching a real path.
# Write BOM-less, and strip one on read for manifests older than this fix.
function Write-Manifest($Path, $Lines) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, [string[]]@($Lines), $utf8NoBom)
}

function Read-Manifest($Path) {
    if (-not (Test-Path $Path)) { return $null }
    return @(Get-Content -Path $Path -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Trim([char]0xFEFF).Trim() } |
        Where-Object { $_ })
}

# --- Pre-flight ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is required. Install from https://git-scm.com/downloads/win"
    exit 1
}

# --- 1. Clone or Update ---
Write-Banner "Syncing Repository"

$RepoDir = Assert-SafeCachePath $RepoDir
$needClone = $true

if (Test-GitRepo $RepoDir) {
    Write-Info "Updating existing clone at $RepoDir"
    $fetch = Invoke-Native git @("-C", $RepoDir, "fetch", "--all", "--prune") -Quiet
    $pull  = Invoke-Native git @("-C", $RepoDir, "pull", "--ff-only") -Quiet
    if ($fetch.ExitCode -eq 0 -and $pull.ExitCode -eq 0) {
        $needClone = $false
    } else {
        # Diverged branch, shallow clone, detached HEAD, or offline. The cache is
        # disposable, so discard it rather than failing the deploy.
        Write-Warn "Update failed (diverged, shallow, or offline) - re-cloning"
    }
} elseif (Test-Path $RepoDir) {
    Write-Warn "Cache at $RepoDir is not a valid git clone - replacing it"
}

if ($needClone) {
    if (Test-Path $RepoDir) { Remove-Item $RepoDir -Recurse -Force -ErrorAction SilentlyContinue }
    $parent = Split-Path $RepoDir -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Write-Info "Cloning into $RepoDir"
    $clone = Invoke-Native git @("clone", $RepoUrl, $RepoDir)
    if ($clone.ExitCode -ne 0 -or -not (Test-GitRepo $RepoDir)) {
        Write-Error "git clone failed. Check network access and that $RepoUrl is reachable."
        exit 1
    }
}
Write-Ok "Repository synced"

# --- 2. Sanitize (data-safe) ---
Write-Banner "Sanitizing Workspace (data-safe)"

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
}

if ($ForceWipe) {
    Write-Warn "Force refresh: clearing only content this deploy previously installed"
    Write-Info "Preserving projects/ (memory + session history), settings.json, credentials,"
    Write-Info "your own agents/skills, and Anthropic's official skills"

    # Agents: drop the managed files, keep everything else. Falling back to the
    # whole tree when no manifest exists would delete user-authored agents, so we
    # deliberately do not.
    $managedAgents = Read-Manifest $ManifestAgents
    if ($managedAgents -and (Test-Path $AgentsDst)) {
        Backup-Path $AgentsDst "agents"
        foreach ($rel in $managedAgents) {
            $target = Join-Path $AgentsDst $rel
            if (Test-Path $target) { Remove-Item $target -Force -ErrorAction SilentlyContinue }
        }
        Get-ChildItem -Path $AgentsDst -Recurse -Directory -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { -not (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue) } |
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Skills: remove only the skill directories this deploy owns.
    $managedSkills = Read-Manifest $ManifestSkills
    if ($managedSkills -and (Test-Path $SkillsDst)) {
        Backup-Path $SkillsDst "skills"
        foreach ($name in $managedSkills) {
            if ($name -match '[\\/]') { continue }
            $target = Join-Path $SkillsDst $name
            if (Test-Path $target) { Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Write-Ok "Managed content cleared - user data untouched"
} else {
    Write-Info "Non-destructive deploy: only Nation of Elites content is replaced"
    Write-Info "Preserving projects/, settings.json, commands/, plugins/, credentials, and anything you authored"
    Write-Ok "No destructive cleanup needed"
}

# --- 3. Deploy Agents ---
Write-Banner "Deploying Agents"

if (-not (Test-Path $AgentsSrc)) {
    Write-Error "Agents source not found at $AgentsSrc"
    exit 1
}

$newAgentList = Get-RelativeFiles $AgentsSrc

# First run under manifest-scoped deploys. We adopt ONLY the files this repo
# currently ships - never the whole existing tree. An unrecognised agent is
# assumed to be yours, so it is left in place rather than purged.
if (-not (Test-Path $ManifestAgents)) {
    Write-Info "No deploy manifest yet - adopting only Nation of Elites files; anything else is left untouched"
    Write-Manifest $ManifestAgents $newAgentList
}

# Agents retired before manifest tracking existed. Removed unconditionally
# (with a backup) because leaving them shadows the canonical replacement.
$legacyRetired = @("07_Orchestrators\Tech_Lead_Orchestrator.md")
foreach ($legacy in $legacyRetired) {
    $legacyPath = Join-Path $AgentsDst $legacy
    if (Test-Path $legacyPath) {
        Backup-Path $legacyPath ("agent-retired-" + (Split-Path $legacy -Leaf))
        Remove-Item $legacyPath -Force -ErrorAction SilentlyContinue
        Write-Info "Removed retired agent: $legacy"
    }
}

# Purge only files we installed before and the repo no longer ships. Anything
# you added yourself is not in the manifest, so it is never a deletion target.
# This replaces robocopy /MIR, which deleted every extra file in the destination.
if (Test-Path $AgentsDst) {
    $previous = Read-Manifest $ManifestAgents
    if ($previous) {
        $stale = @(Compare-Object -ReferenceObject $previous -DifferenceObject $newAgentList |
            Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject })
        if ($stale.Count -gt 0) {
            Backup-Path $AgentsDst "agents"
            foreach ($rel in $stale) {
                $target = Join-Path $AgentsDst $rel
                if (Test-Path $target) {
                    Remove-Item $target -Force -ErrorAction SilentlyContinue
                    Write-Info "Removed stale managed agent: $rel"
                }
            }
            Get-ChildItem -Path $AgentsDst -Recurse -Directory -ErrorAction SilentlyContinue |
                Sort-Object { $_.FullName.Length } -Descending |
                Where-Object { -not (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue) } |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

Write-Info "Copying agents to $AgentsDst"
# /E copies subdirectories including empty ones but, unlike /MIR, never deletes
# anything already in the destination. Removal is the manifest's job above.
robocopy $AgentsSrc $AgentsDst /E /NJH /NJS /NDL /NP /NFL | Out-Null
# robocopy exit codes 0-7 are success (8+ = failure); reset so later logic isn't confused.
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy failed copying agents (code $LASTEXITCODE)"; exit 1 }
$global:LASTEXITCODE = 0
Write-Manifest $ManifestAgents $newAgentList
Write-Ok "Agents deployed"

# --- 4. Deploy Skills ---
Write-Banner "Deploying Skills"

if (Test-Path $SkillsSrc) {
    $newSkillList = Get-TopLevelNames $SkillsSrc

    # Retire skills we shipped previously and no longer do. Scoped to the
    # manifest, so Anthropic's official skills and your own never qualify.
    $previousSkills = Read-Manifest $ManifestSkills
    if ($previousSkills -and (Test-Path $SkillsDst)) {
        $staleSkills = @(Compare-Object -ReferenceObject $previousSkills -DifferenceObject $newSkillList |
            Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject })
        if ($staleSkills.Count -gt 0) {
            Backup-Path $SkillsDst "skills"
            foreach ($name in $staleSkills) {
                if ($name -match '[\\/]') { continue }
                $target = Join-Path $SkillsDst $name
                if (Test-Path $target) {
                    Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Info "Removed retired Nation of Elites skill: $name"
                }
            }
        }
    }

    Write-Info "Installing custom Nation of Elites skills"
    if (-not (Test-Path $SkillsDst)) {
        New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null
    }
    Copy-Item -Path (Join-Path $SkillsSrc "*") -Destination $SkillsDst -Recurse -Force
    Write-Manifest $ManifestSkills $newSkillList
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

# Semgrep is optional. A missing or broken binary must never fail the deploy -
# the SAST *skill* ships regardless, and the MCP plugin works independently.
$semgrepCmd = Get-Command semgrep -ErrorAction SilentlyContinue
if ($semgrepCmd) {
    $sg = Invoke-Native semgrep @("--version") -Quiet
    $sgVersion = ($sg.Output -split "`n" | Where-Object { $_ -match '\d' } | Select-Object -First 1)
    if ($sg.ExitCode -eq 0 -and $sgVersion) {
        Write-Ok "Semgrep installed: v$($sgVersion.Trim())"

        # Check for Semgrep token
        $semgrepSettings = Join-Path (Join-Path $env:USERPROFILE ".semgrep") "settings.yml"
        if (Test-Path $semgrepSettings) {
            Write-Ok "Semgrep token configured ($semgrepSettings)"
        } else {
            Write-Warn "Semgrep token not found. Run 'semgrep login' to authenticate for full rule access."
        }
    } else {
        # Common on Windows: a pip shim resolves on PATH but the interpreter or
        # package behind it is broken or half-installed.
        Write-Warn "Semgrep found on PATH but not runnable (exit $($sg.ExitCode)). Reinstall with: pip install --force-reinstall semgrep"
        Write-Info "Skipping - the Semgrep SAST skill is deployed and unaffected."
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
