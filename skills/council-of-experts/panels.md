# Council Panels by Artifact Type

Default panels. Chair first, then 2-4 members. Total panel size 3-5. All ids are roster agent `name:` values.

| Artifact type | Chair (`opus`) | Members | Notes |
|---------------|----------------|---------|-------|
| Feature spec / FSD / ACs | `product-manager` | `functional-analyst` (scribe), `solution-architect`, `qa-test-planner`, `ux-ui-architect` | Drop `ux-ui-architect` when there is no UI |
| Bug fix / incident | `code-reviewer` | `code-archaeologist`, `sre-specialist`, `qa-engineer` | Add the stack specialist (e.g. `backend-developer`, `react-typescript-expert`) for the affected code |
| Architecture proposal / ADR | `solution-architect` | `cloud-architect`, `api-architect`, `cyber-sentinel`, `performance-optimizer` | Swap `cloud-architect` for `database-expert` on data-heavy designs |
| Security-sensitive change | `cyber-sentinel` | `code-reviewer`, `storage-security-specialist`, `infrastructure-specialist` | Swap in `financial-systems-expert` for payments or ledgers |
| API / contract change | `api-architect` | `functional-analyst` (scribe), `backend-developer`, `code-reviewer`, `integration-specialist` | Use `graphql-architect` instead of `backend-developer` for GraphQL schemas |
| Data / ML change | `ai-strategist` | `ml-engineer`, `data-engineer`, `data-scientist`, `database-expert` | Add `cyber-sentinel` when PII or training data provenance is in scope |
| Mobile | `solution-architect` | `mobile-architect`, `ios-developer`, `android-developer`, `ux-ui-architect` | Drop the platform not in scope |
| UI / UX | `ux-ui-architect` | `accessibility-specialist`, `frontend-developer`, `visual-regression-specialist` | Use the framework specialist (`react-typescript-expert`, `vue-expert`, `nextjs-expert`) in place of `frontend-developer` when known |
| BD proposal / pricing | `business-development-manager` | `proposal-architect`, `market-intelligence-analyst`, `client-success-manager`, `financial-systems-expert` | Drop `financial-systems-expert` when there is no pricing model |
| Content / localization | `book-editor` | `translation-localization-specialist`, `publishing-specialist`, `documentation-specialist` | Use `book-author` as chair for voice/structure questions on a manuscript |
| Release / deploy plan | `cloud-architect` | `devops-engineer`, `sre-specialist`, `qa-test-planner`, `cyber-sentinel` | Swap `cloud-architect` for `program-manager` when the question is scope/schedule, not infrastructure |

## Selection Rules

- **Chair:** the most senior relevant `opus` agent for the artifact. Its lens breaks ties in the verdict; the main session writes the verdict
- **Scribe:** `functional-analyst` whenever a spec, ACs, or traceability are in scope, regardless of row
- **Gate seats:** `code-reviewer` when code is in scope; `cyber-sentinel` when auth, secrets, PII, crypto, or exposure surfaces are in scope
- **User-named members** replace the defaults. Flag (do not silently add) a missing gate seat
- **Mixed artifacts:** chair from the dominant row; swap in at most two members from the secondary row; cap at 5
- **Domain rows not listed** (construction/BIM, Unreal, crypto): take the closest row and swap one member for the domain specialist (`construction-ai-orchestrator`, `unreal-engine-expert`, `crypto-api-developer`)
- Prefer fewer members when the artifact is small. Three well-chosen seats beat five overlapping ones
