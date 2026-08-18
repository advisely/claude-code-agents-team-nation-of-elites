# Design Spec: Pipeline Consolidation — Three Self-Contained Skills

**Date:** 2026-08-18
**Target version:** v4.0.0 (breaking — two publicly-named skills removed)
**Base:** v3.18.0
**Status:** Approved for implementation planning

## Summary

Collapse the five-skill pipeline family into **three self-contained skills**:

| Skill | Role |
|-------|------|
| `pipeline-quality` | Everything except git, release, and deploy. Absorbs `pipeline-review` Passes 1–2. |
| `pipeline-full-build-cloud` | Complete standalone release chain for VPS/container apps. |
| `pipeline-full-build-desktop` | Complete standalone release chain for installable desktop apps. |

`pipeline-full-build` (parent) and `pipeline-review` are **deleted**; their content is
redistributed. The release also fixes a silent gate failure in the severity scale and sweeps
accumulated documentation drift, adding a permanent gate so the drift cannot silently return.

## Context & Constraints

These facts were established by reading the operator's actual deployment scripts
(`~/projects/clearpath`, `~/projects/resumeflex`) and drive most decisions below.

1. **There is no Kubernetes.** Both production apps deploy to a single Hostinger VPS
   (`72.60.115.212`) via SSH + `docker compose`. clearpath rsyncs source and builds remotely;
   resumeflex deploys an image with a `rollback-previous` tag. The current
   `pipeline-full-build-cloud` is written `kubectl`-first, so its deploy and rollback contract
   does not exist for this operator.

2. **The VPS is multi-app.** clearpath, resumeflex, editorinchief and boumiza.com share the host
   and its nginx. Any operation scoped to "the machine" rather than "this app" reaches into a
   neighbour. `resumeflex/deploy-cloud.sh` records a real incident on **2026-07-30** where
   cleanup deleted its own rollback target by counting image *rows* instead of image *IDs*.

3. **The operator has a standing 8-step pipeline** in `resumeflex/CLAUDE.md`
   ("Quality Pipeline — 8 Steps (MANDATORY)"): develop → `eslint --fix` → parallel analysis in a
   single message (`code-simplifier` ∥ `cyber-sentinel` ∥ `code-reviewer`) → remediate including
   pre-existing → opportunistic scan → `qa-engineer` coverage + edge → build → docs. This becomes
   the spine of `pipeline-quality`.

4. **Tooling is asymmetric.** clearpath has `knip.jsonc` and a pnpm/turbo monorepo; resumeflex has
   Playwright + `e2e/` but no knip. Steps must detect, not assume.

5. **Stale test servers are a known hazard.** `resumeflex/CLAUDE.md` documents that a suite can
   silently pass against a sibling app's server on the shared box, which is why Playwright pins
   its own port and asserts health first.

## Changes

### 1. Skill Topology

```
pipeline-quality                    checks only — no git, no release, no deploy
        ^ invoked by both
pipeline-full-build-cloud           backup -> [quality] -> commit -> merge -> push
                                    -> build -> release -> VPS deploy -> prod E2E
                                    -> docs -> purge workers -> cleanup
pipeline-full-build-desktop         backup -> [quality] -> commit -> merge -> push
                                    -> compile -> sign -> installer -> release -> ship feed
                                    -> docs -> purge workers -> cleanup
```

**The deterministic/reasoning split is preserved.** It moves from a skill boundary to a phase
boundary inside `pipeline-quality`: steps 1–9 are deterministic and fail-fast, steps 10–11 are the
reasoning fan-out, and steps 12–14 are gates that consume the output of both. Cheap checks still
gate expensive judgment, in that order. The official `code-review` and `code-simplifier` plugins
remain drop-in alternatives for steps 10–11.

#### 1a. Merge mechanics (each must be explicitly verified)

- **Call-site rewiring.** `skills/feature-workflow/SKILL.md` (Phases 5–6) and
  `skills/pr-ready/SKILL.md` (Step 5) invoke `/pipeline-review`. Both retarget `/pipeline-quality`.
- **`pr-ready` decomposition.** `pr-ready` Phase 1 currently inlines `tsc`, `semgrep` and
  `npm audit` (lines 33–47). It must call `/pipeline-quality` instead, so a check added to the
  gate cannot silently fail to run in `pr-ready`.
- **Frontmatter sweep.** `pipeline-review` must be removed from every `skills:` list —
  `code-reviewer` (`skills: [semgrep-sast, pipeline-quality, pipeline-review]`), `qa-engineer`,
  `devops-engineer`.
- **Description routing.** The merged `pipeline-quality` `description:` must trigger on review
  phrasing ("review my diff", "simplify this code") as well as gate phrasing. Descriptions are the
  routing signal; a merge that advertises only the gate silently stops being selected for review
  requests, and that failure is invisible because the skill still works when it *is* invoked.
- **Variant renumbering.** Both variants reference "Step 1 (Quality Gate)" of `pipeline-quality`.
  With the merged step numbering these cross-references must be updated.
- **Single-home the variant gate additions.** `pipeline-quality` currently carries its own
  "Desktop Variant" / "Cloud Variant" sections *and* each variant carries "Additions to Step 1".
  The variants are the single home; the duplicate sections come out of `pipeline-quality`.

### 2. `pipeline-quality`

Spine = the operator's 8 steps, generalized and stack-adaptive. New or changed steps in **bold**.

| # | Step | Notes |
|---|------|-------|
| 0 | Stack detection | **+ knip decision rule**, **+ version consistency assertion** |
| 1 | Lint + auto-fix | `eslint --fix` / `ruff --fix` |
| 2 | Type check | both processes for Electron |
| 3 | Build | moved early — a broken build must not burn reasoning passes |
| 4 | Security gate (3-part) | unchanged from v3.18.0: `security-guidance` readiness, Semgrep, `/security-review` |
| 5 | Tests | |
| 6 | Test case matrix | happy / non-happy / edge |
| 7 | **Local E2E (Playwright)** | **new** |
| 8 | **Dead code + knip** | **conditional** |
| 9 | Dependency audit | |
| 10 | **Parallel analysis — one message** | `code-simplifier` ∥ `cyber-sentinel` ∥ `code-reviewer` |
| 11 | **Remediation incl. pre-existing** | boy-scout rule |
| 12 | **Zero-debt gate** | **new, blocking** |
| 13 | **No-regression gate** | **new, blocking** |
| 14 | **Local worker purge** | **new** |

#### 2a. Step 0 — knip decision rule

Run `knip` when `knip.json`/`knip.jsonc` exists **or** a workspace monorepo is detected
(`pnpm-workspace.yaml`, `turbo.json`, or a `workspaces` key in `package.json`). Otherwise use
`ts-prune` for single-package TypeScript and `vulture` for Python. Never skip silently — a stack
with no applicable tool records `NOT RUN`, consistent with the v3.18.0 security-gate semantics.

#### 2b. Step 0 — version consistency assertion (new, blocking)

`plugin.json` is the single source of truth. The step fails when any of the following disagree
with it: README version badge, README footer, `CLAUDE.md` version references, skill-count claims
in README (badge, body), `CLAUDE.md` (body, Cowork table) and `plugin.json` description, and the
declared skill count versus `ls -1d skills/*/ | wc -l`.

Rationale: this is the check that would have prevented 3.13.0 / 3.14.0 / 3.18.0 coexisting in one
repo, and 32 / 33 / 35 coexisting as skill counts. Fixing the drift once without this gate
guarantees it returns.

#### 2c. Step 7 — local E2E (Playwright)

Full suite, against a locally-started server:

1. Kill stale listeners on the target port before starting (documented hazard on the shared box).
2. Pin a dedicated port; assert health before the first spec runs.
3. Seed throwaway accounts in a scratch database.
4. `trap`-guaranteed teardown of server, database and accounts.

This is the *exhaustive* run. It never touches production.

#### 2d. Step 12 — zero-debt gate (blocking)

Defined concretely so it is enforceable rather than aspirational. Sourced from the operator's own
Forbidden/Required table.

| Blocks | Detection |
|--------|-----------|
| `TODO`/`FIXME` with no linked task id | grep + issue-reference pattern |
| `as any`, `# type: ignore` with no justification comment | grep |
| Empty `catch` blocks | `silent-failure-audit` skill |
| `.backup` / `.old` / `.deprecated` files | glob |
| Hardcoded secrets, mock data on production paths | Semgrep + grep |
| Dead code | knip / ts-prune / vulture (step 8) |
| Any review finding, Critical through Low | step 10 output |

**Named deferral, never silent.** Blocking on Low severity everywhere can wedge an urgent fix. A
deferral is permitted only when it is (a) justified in the report and (b) written to `PLAN.md`.
An undocumented deferral is a gate failure. This mirrors the existing `NOT RUN is not PASS`
principle: the point is that nothing is carried quietly, not that nothing is ever carried.

#### 2e. Step 13 — no-regression gate (blocking)

- Test count must not decrease versus the previous release (resumeflex already has
  `check:docs --test-count` for exactly this).
- No new `.skip` / `.only` / `xit` without justification.
- Coverage must not fall.
- Previously-passing E2E specs must still pass.
- Bundle/artifact size within threshold of the previous release.

#### 2f. Step 14 — local worker purge

Identify processes above a CPU threshold that are stale dev servers, orphaned test runners or
detached build jobs. Scope by working directory or cgroup — a blind `pkill` is a defect even when
it works.

### 3. `pipeline-full-build-cloud`

| Step | Change |
|------|--------|
| 0 | **Preflight (new):** refuse to start on a dirty tree or a branch behind `origin` |
| 1 | Failsafe backup — local `git bundle` **+ remote `pg_dump` on the VPS** |
| 2 | Verify — `/pipeline-quality` |
| 3–5 | Integrate — commit (ex-`pipeline-review` Pass 3) → merge → push |
| 6 | **Build — compose-on-VPS primary**, k8s demoted to a secondary branch |
| 7 | Release — tag + GitHub release |
| 8 | **Deploy — rewritten for compose over SSH.** Rollback target captured **by image ID, not tag row** |
| 9 | **Prod E2E (new)** — critical path only, real temp accounts |
| 10 | Post-deploy verification + rollback gate |
| 11 | Documentation — project docs, then Claude docs |
| 12 | **Purge workers (new)** — local **and** VPS, app-scoped |
| 13 | Cleanup — **app-scoped, ID-based**; volumes preserved; sibling apps untouched |

#### 3a. Local E2E vs prod E2E

They are different suites, not the same suite run twice.

| | Local (quality step 7) | Prod (cloud step 9) |
|---|---|---|
| Scope | Full suite | Critical path only — login, one authed write, one authed read, logout |
| Accounts | Seeded, scratch DB | **Real temp accounts**, namespaced + torn down |
| Runs against | Own server, pinned port | Live HTTPS through real nginx + TLS |
| Proves | The code is correct | The **deployment** is correct |
| On failure | Blocks the commit | Triggers the rollback gate |

**Admission rule:** a spec earns a place in the prod run only if it can fail in production while
passing locally. Everything else stays local.

Justification from project history: the v6.7.x contact-form failure was a `src/proxy.ts` 401 that
no local test could observe; a Playwright run against production is what found it
(`resumeflex/CHANGELOG.md:1251`).

#### 3b. Prod E2E safety requirements

- Accounts namespaced `e2e+<runid>@...` so orphans are identifiable.
- `trap`-guaranteed teardown.
- **Orphan sweep** for accounts left behind by earlier failed runs, before creating new ones.
- Analytics-exclusion header on all test traffic.
- The step **refuses to start** if teardown credentials are absent — better to skip than to
  create accounts that cannot be removed.

#### 3c. Rollback and the tag question

A prod E2E failure lands *after* the tag and release exist. It therefore cannot block in the
ordinary sense; it triggers rollback. The release is then marked **superseded** rather than having
its tag deleted, because deleting a published tag breaks anyone who already fetched it.

#### 3d. Cleanup and worker purge scoping

Every destructive or resource-claiming step takes an app scope. Specifically:

- Keep current **and** rollback images, matched by image ID (the 2026-07-30 lesson).
- Never `docker system prune -a`, never `--volumes`.
- Volumes hold the database and uploads; they are never blanket-pruned.
- Sibling apps' images, containers and volumes are out of scope by construction.

### 4. `pipeline-full-build-desktop`

Same spine as §3 with desktop-specific middle steps. Retains Electron ABI native-module rebuilds,
code signing, notarization and packaged-artifact validation. Gains:

- The **security precondition** text added to the parent and cloud in v3.18.0 but skipped for
  desktop — a real parity gap.
- Zero-debt and no-regression gates via `/pipeline-quality`.
- **Packaged-binary E2E stays in this skill**, in artifact validation — not in `pipeline-quality`.
  Ordering makes this unavoidable: `pipeline-quality` step 7 runs before packaging exists, so it
  can only exercise the dev build. Desktop therefore runs E2E twice against two different
  artifacts, deliberately: the dev build early to fail fast, the signed artifact late because
  missing runtime deps, broken asar paths and native-module load failures appear nowhere else.
- The prod-E2E analogue: update-feed verification plus a clean-VM install smoke after publish.
- Worker purge is local only; there is no VPS in this path.

### 5. Blast Radius & Migration

- 53 references to `pipeline-full-build`, 39 to `pipeline-review`.
- Affected: `README.md`, `SKILLS.md`, `CLAUDE.md`, `docs/rules/orchestration.md`,
  `docs/rules/skills-integration.md`, `agents/.../DevOps_Engineer.md`,
  `agents/.../Code_Reviewer.md`, `skills/feature-workflow/`, `skills/pr-ready/`,
  `skills/pipeline-quality/`.
- `CHANGELOG.md` mentions are **left untouched** — they are a historical record, not references.
- Skill count 35 -> 33 everywhere it is claimed.
- Version 4.0.0: removing two publicly-named skills that other skills and agents reference is a
  breaking change.

### 6. Docs-Drift Sweep

All of the following are verified defects in the tree at v3.18.0.

| Location | Defect |
|----------|--------|
| `README.md:13` | Skills badge says 32; actual is 35 -> 33 |
| `README.md:16` | Version badge says 3.13.0 |
| `README.md:682` | Footer says v3.14.0 and 33 skills |
| `CLAUDE.md:52` | "35 custom skills" |
| `CLAUDE.md:142` | Cowork table says "Skills (33)" |
| `docs/rules/skills-integration.md:35` | `cyber-sentinel` -> `owasp-checklist` — skill does not exist |
| `docs/rules/skills-integration.md:31` | `code-reviewer` map disagrees with its own frontmatter in both directions |
| `CONTRIBUTING.md:408-413` | **11 of 18 skill names are phantom**: `owasp-checklist`, `penetration-testing`, `terraform-templates`, `pdf-tools`, `excel-automation`, `word-templates`, `playwright-patterns`, `test-strategies`, `microservices-patterns`, `event-driven-design`, `api-design` |
| `skills/security-audit/SKILL.md:419-421` | Links `penetration-testing.md`, `compliance.md`, `incident-response.md`; the directory contains only `SKILL.md` |

**`security-audit` is the most serious.** Those are Level-3 progressive-disclosure pointers — a
runtime dependency, not a doc typo. An agent following them mid-audit gets file-not-found, and its
most likely recovery is to continue on what it already has and report a completed audit. Either
author the three files or remove the links; do not leave them dangling.

**Not defects:** `pdf`, `docx`, `pptx`, `xlsx`, `canvas-design`, `webapp-testing` and
`artifacts-builder` are official Anthropic / Cowork built-ins and are deliberately absent from
`skills/`.

### 7. Severity Unification

Currently:

```
pipeline-review gate:  Critical | High | Medium | Low   ("any Critical or High blocks")
code-reviewer emits:   Critical | Major | Minor          (never emits High)
```

The agent's **Major** means "should fix soon" — semantically the skill's **High**, which blocks —
but it arrives wearing the skill's **Medium** colour, which does not. The gate therefore reads its
delegate's blocking findings as non-blocking, and the report looks normal either way.

This is a silent gate failure, in the gate that preloads `silent-failure-audit`. Resolution: one
four-level scale (Critical / High / Medium / Low) used by both the merged `pipeline-quality`
review phase and `agents/.../Code_Reviewer.md`. **Ships in this release**, not a later one.

Additionally, `code-reviewer` declares `tools: Read, Grep, Glob, Bash` — no `Edit` or `Write`. The
merged skill must state explicitly that **the invoking agent applies edits**, so nobody expects
the subagent to do it.

### 8. Files to Modify

- `skills/pipeline-quality/SKILL.md` — rewritten (§2, §7)
- `skills/pipeline-full-build-cloud/SKILL.md` — rewritten (§3)
- `skills/pipeline-full-build-desktop/SKILL.md` — extended (§4)
- `skills/pr-ready/SKILL.md` — Phase 1 delegates; Phase 5 routes to the variant skills
- `skills/feature-workflow/SKILL.md` — Phases 5–6 retarget
- `skills/security-audit/SKILL.md` — dangling Level-3 links
- `agents/03_Engineering_Division/Code_Excellence_Guild/Code_Reviewer.md` — severity scale, `skills:`
- `agents/04_Quality_Assurance_Battalion/*.md`, `agents/05_SecOps_and_Infrastructure_Division/DevOps_Engineer.md` — `skills:`
- `CLAUDE.md`, `README.md`, `SKILLS.md`, `CONTRIBUTING.md`, `.claude-plugin/plugin.json`
- `docs/rules/orchestration.md`, `docs/rules/skills-integration.md`
- `CHANGELOG.md` — new v4.0.0 entry

### 9. Files to Delete

- `skills/pipeline-full-build/` (entire directory)
- `skills/pipeline-review/` (entire directory)

### 10. Out of Scope

- `clearpath/deploy-cloud.sh` and `resumeflex/deploy-cloud.sh` are **not** modified. They informed
  this design; changing them is separate work in separate repositories.
- No agent roster changes, no model/frontmatter changes beyond the `skills:` sweep and the
  severity scale.

## Acceptance Criteria

1. `skills/` contains exactly 33 directories; `pipeline-full-build` and `pipeline-review` are gone.
2. No file outside `CHANGELOG.md` and this spec references `/pipeline-review` or
   `/pipeline-full-build`.
3. Every skill name referenced in `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`,
   `docs/rules/*.md` and every agent `skills:` list resolves to a real directory, or is a
   documented official/Cowork built-in.
4. `plugin.json`, README badge, README footer and `CLAUDE.md` all state **4.0.0** and **33 skills**.
5. One severity scale appears in both the merged skill and `Code_Reviewer.md`.
6. Each of the three skills is independently invocable and complete — no skill references a step
   owned by a deleted skill.
7. `git status` is clean and the branch is not behind `origin` at completion.
