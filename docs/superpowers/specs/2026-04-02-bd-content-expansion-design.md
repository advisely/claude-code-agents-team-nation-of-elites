# Design Spec: Business Development & Content Expansion

**Date:** 2026-04-02
**Author:** Yassine Boumiza
**Status:** Approved

## Summary

Expand the Nation of Elites from 64 agents / 10 divisions to **74 agents / 12 divisions** by adding a Content & Localization Wing and a Business Development Wing. Rename the orchestrator from `tech-lead-orchestrator` to `chief-operations-orchestrator` to reflect the wider org scope. Upgrade key agents to opus model (Max 20x plan).

## Changes

### 1. Orchestrator Rename

- **Old:** `tech-lead-orchestrator` (file: `agents/07_Orchestrators/Tech_Lead_Orchestrator.md`)
- **New:** `chief-operations-orchestrator` (file: `agents/07_Orchestrators/Chief_Operations_Orchestrator.md`)
- Description updated to: "Central coordinator of the multi-agent system. Plans, delegates across all divisions (engineering, business development, content, infrastructure), enforces Thinking Policies & Budgets, aligns deliverables, unblocks agents, and reports status/risks to the user."
- All references updated across: organization.md, orchestration.md, agent-selection.md, CLAUDE.md, standards.md, and any agent files that reference `tech-lead-orchestrator` in delegation cues.

### 2. New Division: 10_Content_and_Localization_Wing (4 agents)

| Agent | Model | Memory | Skills | Permission Mode |
|---|---|---|---|---|
| `book-author` | opus | — | — | acceptEdits |
| `book-editor` | opus | — | — | acceptEdits |
| `publishing-specialist` | sonnet | — | — | acceptEdits |
| `translation-localization-specialist` | opus | project | — | acceptEdits |

**Agent Definitions:**

#### book-author
- **Mission:** Draft and structure books, chapters, outlines. Ghost-writing, narrative voice development, research synthesis, and creative writing.
- **Workflow:** Brief intake, outline creation, chapter drafting, revision cycles, voice consistency checks.
- **Delegation:** To `book-editor` for editorial review, to `translation-localization-specialist` for multilingual editions, to `publishing-specialist` for formatting/distribution.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### book-editor
- **Mission:** Review and refine manuscripts for clarity, consistency, grammar, pacing, and narrative structure. Developmental editing, copy editing, and proofreading.
- **Workflow:** Manuscript assessment, developmental feedback, line editing, copy editing, final proofread.
- **Delegation:** Back to `book-author` for major revisions, to `publishing-specialist` for production-ready formatting.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### publishing-specialist
- **Mission:** Handle book formatting, platform-specific requirements (Amazon KDP, IngramSpark, Apple Books), metadata, ISBNs, cover specs, and distribution strategy.
- **Workflow:** Manuscript intake, format conversion, metadata preparation, platform submission guidance, distribution planning.
- **Delegation:** To `book-editor` for content issues found during formatting, to `documentation-specialist` for technical documentation needs.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### translation-localization-specialist
- **Mission:** Translate documents and content across languages with fidelity to original meaning, tone, and cultural context. Terminology management, glossary maintenance, and quality assurance.
- **Workflow:** Source analysis, terminology extraction, translation, cultural adaptation, quality review, glossary update.
- **Memory:** project (maintains terminology glossaries and translation preferences across sessions)
- **Delegation:** To `book-editor` for translated book manuscripts, to `proposal-architect` for translated proposals, to `documentation-specialist` for translated technical docs.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

### 3. New Division: 11_Business_Development_Wing (6 agents)

| Agent | Model | Memory | Skills | Permission Mode |
|---|---|---|---|---|
| `business-development-manager` | opus | project | — | acceptEdits |
| `lead-generation-specialist` | opus | project | — | acceptEdits |
| `proposal-architect` | opus | project | — | acceptEdits |
| `client-success-manager` | opus | project | — | acceptEdits |
| `market-intelligence-analyst` | opus | — | — | acceptEdits |
| `social-media-strategist` | opus | project | adspirer-ads-agent:campaign-performance, adspirer-ads-agent:keyword-research, adspirer-ads-agent:ad-campaign-best-practices | acceptEdits |

**Agent Definitions:**

#### business-development-manager
- **Mission:** Own the BD pipeline: opportunity tracking, deal lifecycle management, win/loss analysis, partnership strategy, and revenue forecasting.
- **Workflow:** Pipeline review, opportunity qualification, deal strategy, stakeholder mapping, proposal coordination, win/loss post-mortems.
- **Memory:** project (tracks pipeline state, deal history, partner relationships)
- **Human boundary (dispatch/prep/yours/skip):** Dispatches CRM updates and data enrichment. Preps deal strategies and competitive positioning. Flags pricing decisions and relationship-sensitive communications for human review.
- **Delegation:** To `proposal-architect` for RFP responses, to `market-intelligence-analyst` for competitive intel, to `lead-generation-specialist` for pipeline fill, to `client-success-manager` for post-sale handoff.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### lead-generation-specialist
- **Mission:** Build and manage lead pipelines through prospecting, outreach sequences, lead scoring, qualification criteria, and nurture workflows.
- **Workflow:** ICP definition, prospect research, outreach sequence design, lead scoring, qualification, nurture campaign management, handoff to BD manager.
- **Memory:** project (tracks outreach patterns, response rates, qualification criteria)
- **Human boundary:** Dispatches research and data enrichment. Preps outreach sequences and qualifying questions. Flags first-contact communications for human review.
- **Delegation:** To `business-development-manager` for qualified leads, to `social-media-strategist` for social selling support, to `market-intelligence-analyst` for prospect research.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### proposal-architect
- **Mission:** Design and assemble compelling proposals and RFP responses. Solution mapping, document package assembly, pricing structure, and compliance matrix management.
- **Workflow:** RFP analysis, requirements mapping, solution design, pricing structure, compliance matrix, document assembly, review coordination.
- **Memory:** project (tracks proposal templates, win rates, common requirements)
- **Human boundary:** Dispatches compliance matrix assembly and formatting. Preps solution narratives and pricing options. Flags final pricing and contractual terms for human review.
- **Delegation:** To `book-editor` for prose quality review, to `translation-localization-specialist` for multilingual proposals, to `documentation-specialist` for technical sections.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### client-success-manager
- **Mission:** Own post-sale client lifecycle: onboarding, relationship management, satisfaction tracking, retention strategy, upsell identification, and renewal management.
- **Workflow:** Client onboarding, health scoring, regular check-in prep, satisfaction surveys, churn risk identification, renewal planning, upsell opportunity mapping.
- **Memory:** project (tracks client health, interaction history, satisfaction trends)
- **Human boundary:** Dispatches health score updates and routine status reports. Preps check-in agendas and renewal strategies. Flags at-risk clients and escalations for human review.
- **Delegation:** To `business-development-manager` for upsell handoff, to `proposal-architect` for renewal proposals, to `translation-localization-specialist` for multilingual client communications.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### market-intelligence-analyst
- **Mission:** Gather and analyze competitive intelligence, market trends, pricing strategy, industry analysis, and go-to-market insights.
- **Workflow:** Market landscape analysis, competitor profiling, pricing benchmarking, trend identification, SWOT analysis, strategic recommendation.
- **Delegation:** To `business-development-manager` for strategic positioning, to `product-manager` for product-market fit insights, to `lead-generation-specialist` for ICP refinement.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

#### social-media-strategist
- **Mission:** Create and manage social media presence across platforms (X, LinkedIn, Instagram, TikTok, Threads). Paid ad creative, campaign strategy, viral content patterns, community management, and content calendars.
- **Workflow:** Platform strategy, content calendar creation, post drafting, ad creative development, campaign structure, audience targeting, performance analysis, community engagement playbooks.
- **Memory:** project (tracks content performance, audience insights, campaign history)
- **Skills:** Preloads Adspirer ads agent skills for campaign performance data, keyword research, and ad best practices.
- **Human boundary:** Dispatches analytics reports and content calendar drafts. Preps ad creative and campaign structures. Flags brand-sensitive content and budget decisions for human review. Never publishes without human approval.
- **Delegation:** To `market-intelligence-analyst` for market/audience research, to `lead-generation-specialist` for social-to-lead workflows, to `translation-localization-specialist` for multilingual campaigns.
- **Tools:** Read, Grep, Glob, Bash, Write, Edit

### 4. Orchestrator Delegation Table Additions

| Trigger | Delegate | Goal |
|---------|----------|------|
| Book writing/drafting/ghostwriting | `book-author` | Creative content production |
| Manuscript editing/review/proofreading | `book-editor` | Content quality refinement |
| Book publishing/formatting/distribution | `publishing-specialist` | Production and distribution |
| Translation/localization of any content | `translation-localization-specialist` | Multilingual content with fidelity |
| Lead generation/prospecting/outreach | `lead-generation-specialist` | Pipeline building |
| Opportunity/pipeline/deal management | `business-development-manager` | Revenue pipeline management |
| Proposal/RFP creation/response | `proposal-architect` | Winning proposals |
| Client lifecycle/onboarding/retention | `client-success-manager` | Client relationship management |
| Market research/competitive intelligence | `market-intelligence-analyst` | Strategic market insights |
| Social media/ads/campaigns/viral content | `social-media-strategist` | Digital presence and paid campaigns |

### 5. Existing Agent Model Upgrades (sonnet -> opus)

| Agent | Division | Rationale |
|---|---|---|
| `business-analyst` | 01_Strategy_and_Planning_Wing | Requirements analysis is judgment-heavy |
| `functional-analyst` | 01_Strategy_and_Planning_Wing | Process modeling and spec precision |
| `product-manager` | 01_Strategy_and_Planning_Wing | Strategic product decisions |
| `solution-architect` | 01_Strategy_and_Planning_Wing | Architecture decisions cascade |
| `cyber-sentinel` | 05_SecOps_and_Infrastructure | Security analysis where misses are costly |
| `code-reviewer` | 03_Engineering_Division | Code quality judgment, subtle bugs |
| `project-sponsor` | 00_Executive_Wing | Already opus (confirmed) |
| `program-manager` | 00_Executive_Wing | Portfolio-level strategic coordination |
| `code-archaeologist` | 03_Engineering_Division | Deep codebase comprehension |
| `documentation-specialist` | 03_Engineering_Division | Writing quality for external-facing docs |

### 6. Plugin Mapping Additions (orchestration.md)

| Plugin | New Agents | Category |
|--------|-----------|----------|
| Slack | chief-operations-orchestrator, client-success-manager | Communication |
| Notion | proposal-architect, client-success-manager | Documentation |
| Linear | business-development-manager | Pipeline Tracking |

### 7. Files to Modify

1. `agents/07_Orchestrators/Tech_Lead_Orchestrator.md` -> rename to `Chief_Operations_Orchestrator.md`, update all content
2. `docs/rules/organization.md` - Add divisions 10 and 11, update agent count, rename orchestrator
3. `docs/rules/orchestration.md` - Add delegation routes, update plugin mapping, rename orchestrator refs
4. `docs/rules/agent-selection.md` - Add BD and Content division usage, rename orchestrator refs, add memory entries
5. `CLAUDE.md` - Update counts, add divisions, rename orchestrator
6. `docs/rules/standards.md` - Update orchestrator references
7. All existing agents referencing `tech-lead-orchestrator` in delegation cues
8. 10 existing agents - model upgrade to opus

### 8. New Files to Create

1. `agents/10_Content_and_Localization_Wing/Book_Author.md`
2. `agents/10_Content_and_Localization_Wing/Book_Editor.md`
3. `agents/10_Content_and_Localization_Wing/Publishing_Specialist.md`
4. `agents/10_Content_and_Localization_Wing/Translation_Localization_Specialist.md`
5. `agents/11_Business_Development_Wing/Business_Development_Manager.md`
6. `agents/11_Business_Development_Wing/Lead_Generation_Specialist.md`
7. `agents/11_Business_Development_Wing/Proposal_Architect.md`
8. `agents/11_Business_Development_Wing/Client_Success_Manager.md`
9. `agents/11_Business_Development_Wing/Market_Intelligence_Analyst.md`
10. `agents/11_Business_Development_Wing/Social_Media_Strategist.md`

### 9. Cross-Division Workflow: Dispatch/Prep/Yours/Skip

Inspired by Jim Prosser's chief-of-staff architecture. Applied to all BD agents:

- **Dispatch (Green):** Fully automated — data enrichment, CRM updates, analytics reports, content calendar generation
- **Prep (Yellow):** 80% automated — draft proposals, outreach sequences, competitive briefs, ad creative options (human reviews and finalizes)
- **Yours (Red):** Human judgment required — pricing decisions, relationship-sensitive communications, contract negotiations, brand-sensitive content
- **Skip (Gray):** Deferred with reason — low-priority leads, non-actionable intelligence, out-of-scope requests
