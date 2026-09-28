# Release Process & Lessons Learned

Maintainer checklist for cutting a Nation of Elites release. This repo ships Markdown agents/skills, two deploy scripts, and plugin manifests — there is no app build, container, or VPS target, so the app-oriented steps of `/pipeline-full-build-*` (Stryker, knip, Playwright, image builds, VPS deploy) record **NOT RUN / N/A**, never a pass.

## Checklist

1. **Branch** — `feat/vX.Y.Z-<topic>` or `fix/vX.Y.Z-<topic>` off `main`.
2. **Version** — bump `.claude-plugin/plugin.json` only; it is the single source of truth.
3. **Consistency** — `bash scripts/check-version-consistency.sh` must print `PASS` (README badges/footer, skill counts, both manifests, plugin name).
4. **Scripts** — `bash -n scripts/deploy_agents.sh`, `shellcheck scripts/deploy_agents.sh`, and a PowerShell parser check of `scripts/deploy_agents.ps1` (from WSL: `powershell.exe -NoProfile -NonInteractive -Command "[System.Management.Automation.Language.Parser]::ParseFile('<wslpath -w path>',[ref]$null,[ref]$e); $e"`).
5. **Roster** — `grep -rh '^model:' agents | sort | uniq -c` matches the counts quoted in CLAUDE.md, README, and [sdk-compliance.md](sdk-compliance.md); no agent sets `effort:` or `model: haiku`.
6. **CHANGELOG** — dated entry listing every changed file (`git diff --stat main`).
7. **Merge** — `git merge --no-ff` into `main`, push.
8. **Tag + GitHub release** — `git tag -a vX.Y.Z` on the merge commit, `git push origin vX.Y.Z`, `gh release create vX.Y.Z --notes "$(cat <changelog section>)"` (a snap-installed `gh` cannot read `/tmp`, so pass notes inline or from `$HOME`). **A version is not released until the tag and release exist.**
9. **Deploy locally** — `bash scripts/deploy_agents.sh` (WSL/Linux/macOS) and `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File scripts/deploy_agents.ps1` (Windows); then diff `agents/` against `~/.claude/agents/` on both sides (`diff -rq --strip-trailing-cr`, since the Windows clone uses `core.autocrlf=true`). Use `--all-homes` on WSL when both `/root/.claude` and the user's home have Claude history.
10. **Smoke test the models, not the files** — on each platform run `claude -p --agent <moved-or-changed agent> --max-turns 1 --output-format json "Reply with exactly: OK"` and read `modelUsage`. Expect the tier's current model (e.g. `claude-sonnet-5-5` / `claude-opus-5-5`). Discard the first one or two runs after a deploy or `claude update`, then require three clean runs in a row.

## Lessons Learned

| Release | What went wrong | Rule now |
|---------|-----------------|----------|
| v4.0.0–v4.0.1 | `marketplace.json` description drifted because nothing read it | Consistency script checks both manifests (step 3) |
| v4.0.1 | Deploy could delete user-authored agents | Deploy only removes paths listed in its own `~/.claude/.noe-manifest-*` |
| v4.1.1 | `Read-Host` crashed under `powershell -NonInteractive`; native stderr rendered as `ErrorRecord` noise | Gate prompts on `Test-Interactive`; call natives through `Invoke-Native` |
| v4.1.0–v4.1.1 | Merged and pushed but never tagged or released on GitHub | Step 8 is mandatory; backfilled in v4.2.0 |
| v4.2.0 | Model aliases move only on a new enough Claude Code, and never on Bedrock/Vertex/Foundry/Claude Platform on AWS — an old install silently runs older models | Deploy scripts warn on Claude Code < 2.1.284 and on unpinned third-party providers |
| v4.2.0 | Parallel doc edits by several agents: a late message reached an agent after it finished; wording drifted between files | Give each agent disjoint file ownership; the lead fills cross-file placeholders; a final reviewer checks facts against one shared brief |
| v4.2.0 | Windows Claude Code was 2.1.282 while WSL was 2.1.284 — the moved agents would have run on Sonnet 5 on Windows | The deploy preflight flags it per platform; run `claude update` on **every** platform before the smoke test |
| v4.2.0 | The first headless sessions after deploy/update loaded a random subset of agents (`--agent ... not found`) and once served the previous Sonnet; repeated runs were clean | Treat the first runs after a deploy or update as warm-up; judge only on repeated runs (step 10) |
| v4.2.0 | `gh release create --notes-file /tmp/...` failed under snap confinement | Pass release notes inline (step 8) |
| v4.2.0 | A steering line told agents to "use the search tool" when their `tools:` had none | Condition tool-dependent steering on availability, or add the tool deliberately |

## Model-Release Alignment Pattern

When Anthropic ships a model: research from official docs first (write a dated brief), update [sdk-compliance.md](sdk-compliance.md) / [standards.md](standards.md) / [thinking-policies.md](thinking-policies.md) / [orchestration.md](orchestration.md), keep agents on aliases (no frontmatter sweep unless a tier moves), keep CLAUDE.md to a pointer, and bump the minor version.
