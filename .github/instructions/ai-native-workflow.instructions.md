---
applyTo: '**/*'
---

# AI-Native Workflow

Routing layer between user intent and the specialized skills that own the rules. Load first on every non-trivial task.

## Critical

- **Low confidence means Phase 3 is incomplete.** If the would-be confidence is **< 5**, do **NOT** emit Phase 4. Return to Phase 3 and **ASK the user** for the missing primary inputs (URL, OpenAPI link, field list, area name). Phase 4 exists for honest _trade-off_ decisions, not for documenting "I don't have enough data" — that belongs in a question to the user. This rule is the most leveraged in the workflow: it is what stops the agent from emitting plausible-looking plans built on guesses.
- **Ask, don't invent.** Never guess folder names, file paths, env-var names, enum values, credentials, or message strings. `ls`, `grep`, `playwright-cli`, OpenAPI — or ask.
- **Refuse placeholders.** Guessed selectors, unverified message strings, made-up enum values, secret-shaped strings — refuse and re-explore. **`TODO` / `skeleton` / "to fill in later" outputs count as placeholders too** — offering a "skeleton page object with TODO locators while we wait for `playwright-cli`" is the same failure mode as inventing locators outright; don't.
- **Verify the user's premise even in Direct Mode.** Before applying a one-line fix, confirm the reported defect actually exists (the typo on the cited line, the import the user wants removed, the value the user says is currently set). If the premise doesn't match the file, switch out of Direct Mode and ASK — applying a "fix" to a defect that isn't there invents a change.
- **Specialized skills own the rules.** This skill never restates rules from `api-testing`, `page-objects`, etc. It tells you **which skill to load** and **in what order**.
- **The Constitution (the always-on instructions wrapping these skills) is the safety floor.** MUST/SHOULD/WON'T tables are hard stops; they take precedence over any prose, template, or example.
- **Audit-then-edit by default.** For any non-trivial change, follow the 8-phase workflow below. Phase 4 (Plan + Confidence) is mandatory before Phase 6 (Apply).
- **Confidence gate is required.** Every Plan output must include a 1-10 confidence + rationale + unknowns block. See "Phase 4" below.
- **Exploration is non-negotiable.** UI → `playwright-cli` only (no IDE browser MCP, no Cursor browser, no `playwright codegen`). API → OpenAPI/docs first, live HTTP only as fallback.
- **One skill at a time.** Load skills sequentially per the routing table. Don't stack 5 skills' Critical blocks before starting work.
- **After any test edit, run the affected tests.** On red, load `debugging` — never suppress, never bump timeouts.

## Main Workflow (8 Phases)

Every non-trivial task runs through these phases in order.

| #   | Phase                   | Generic substeps                                                                                                                                                                                         | Flow-specific substeps owned by                                                                                                                 |
| --- | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Classify intent**     | Match user request → intent class (codegen / edit / refactor / debug / explore / config).                                                                                                                | —                                                                                                                                               |
| 2   | **Route**               | Pick first skill from routing table. Codegen → `common-tasks`. Other → direct skill.                                                                                                                     | —                                                                                                                                               |
| 3   | **Explore**             | Confirm what's known vs unknown; gather evidence per flow. **If a primary input is missing (URL, OpenAPI, area folder, field list), ASK the user before advancing — do NOT carry the gap into Phase 4.** | UI: `playwright-cli`. API: `api-testing` Phase 1 (OpenAPI). Refactor: `refactor-values` Phase 1 (impact grep). Debug: `debugging` capture step. |
| 4   | **Plan + Confidence**   | Produce proposal block (see format below).                                                                                                                                                               | — (owned here)                                                                                                                                  |
| 5   | **Human gate**          | Wait for confirm / reject / rework. On reject → return to Phase 3 with stated gap.                                                                                                                       | —                                                                                                                                               |
| 6   | **Apply**               | Edits per leaf-skill rules. Re-check Critical blocks of every loaded skill.                                                                                                                              | leaf skill                                                                                                                                      |
| 7   | **Verify**              | Lint + run affected tests. Red → load `debugging`.                                                                                                                                                       | `debugging` (on red), `refactor-values` Phase 4 (refactor), `api-testing` Phase 5 (API coverage matrix)                                         |
| 8   | **Report + commit ask** | Files changed, line counts, lint status. Ask before committing.                                                                                                                                          | —                                                                                                                                               |

### Phase 4 — Confidence-Gate Format (mandatory)

Every Plan output before the human gate uses this shape:

```
## Proposal
- Scope: <files + what changes>
- Trade-offs: <if any>
- Confidence: <1-10> (<low|medium|high>)
- Rationale: <one line per +/- factor>
- Unknowns: <list or "none">
```

**Confidence rules:**

- **< 5** → **do NOT emit Phase 4.** Exploration is incomplete. Return to Phase 3 and **ASK the user** for the missing primary input (URL, OpenAPI source, area folder, field list, etc.). Frame the gap as questions, not as a low-confidence proposal.
- **5-7** → emit Phase 4 with explicit unknowns. Proceed only if the human accepts the trade-offs at this confidence level.
- **≥ 8** → full evidence in hand; proceed normally.
- **≥ 9** only if: explicit OpenAPI / spec match, no `{area}` ambiguity, no missing enum / env / credential, no untested branch, no in-flight conflicting work.
- **Rejection by human** → re-enter Phase 3 with stated gap. Do **not** retry Phase 4 with the same plan.

## Routing Table (intent → first skill)

| User intent                                 | First skill             | Then chains to                                            |
| ------------------------------------------- | ----------------------- | --------------------------------------------------------- |
| "Add tests for `POST /api/...`"             | `api-testing`           | `data-strategy`, `enums`, `type-safety`, `debugging`      |
| "Add a page object for X"                   | `page-objects`          | `selectors`, `playwright-cli`, `enums`, `fixtures`        |
| "Generate prompt for X" / "How do I add Y?" | `common-tasks`          | matching specialized skill                                |
| "Test failing / flaky"                      | `debugging`             | `api-testing`, `selectors`, `fixtures`, `refactor-values` |
| "Rename enum / change static value"         | `refactor-values`       | `enums` or `data-strategy` → `debugging`                  |
| "Create factory for X"                      | `data-strategy`         | `type-safety`, `api-testing`                              |
| "Wire setup helper / helper fixture"        | `helpers` or `fixtures` | `api-testing` Phase 8                                     |
| "Add env var / config / utility URL"        | `config`                | `enums`, `type-safety`                                    |
| "Add enum / endpoint / message"             | `enums`                 | `playwright-cli` for live-text verification               |
| "Refactor Zod schema / convert any → typed" | `type-safety`           | `api-testing`                                             |
| "Add spec file / tag / structure question"  | `test-standards`        | `data-strategy`, `api-testing`, `page-objects`            |
| "How does this scaffold work with AI?"      | **this skill**          | relevant specialized skill                                |

If intent matches none of the above → default to `common-tasks` or ask the user to clarify.

## Direct Mode (skip audit-then-edit)

For trivial work (one-line fix, obvious typo, single import) the agent applies and reports back. The user can say "just do it" once to opt out of audit-then-edit for the rest of the session for trivial work. Substantive changes still go through the 8-phase workflow.

**Even in Direct Mode, verify the user's premise before editing.** Open the cited file, find the cited line, confirm the reported defect is actually there. If the typo isn't on that line, the import isn't where the user said, or the value isn't what the user claims it currently is — stop and report the mismatch instead of applying a "fix" to a defect that doesn't exist. This is the same anti-invention principle as Phase 3 ASK, scaled to one-line work.

## When to Stop and Ask

- Path / folder name unknown (`ls` first; if still unclear, ask).
- Enum value / message text / endpoint path unknown (`playwright-cli` for UI, OpenAPI for API; ask if neither).
- Two valid approaches with meaningful trade-offs (architectural decisions belong to the human).
- A skill's Critical rule conflicts with the user's request (raise it; never silently bypass).

### Conversation Contract (inline summary)

- **Audit-then-edit (default for non-trivial work).** State the goal → propose scope (Phase 4 block: scope, trade-offs, confidence + rationale + unknowns) → human approves/modifies/rejects → apply → report files / lint status / ask-to-commit.
- **Direct mode (trivial work).** One-line fixes, typos, single imports — apply and report. The user can say "just do it" once to opt out for the rest of a session for trivial work; substantive changes still go through audit-then-edit.
- **Stop and ask** when: a primary input is missing (URL, OpenAPI, area folder, field list); a path / enum / message text is unknown and `ls` / `playwright-cli` / OpenAPI does not resolve it; two valid approaches have meaningful trade-offs (architectural choice belongs to the human); a Critical rule conflicts with the request.
- **Refuse** when asked to: ship placeholder selectors / guessed UI text; hardcode credentials, URLs, or endpoint paths; suppress a test failure (`try/catch` on `expect`, raised timeouts, silent `.skip`); drop `z.strictObject()` for `z.object()`, use `any`, use XPath, or use `page.waitForTimeout(...)`. Route to the matching Critical rule instead.
- **After rejection** re-enter Phase 3 (Explore) with the stated gap as the new evidence target. Do not retry Phase 4 with the same plan dressed differently.

## Common Critical Rules to Re-Check in Phase 6

Surface across multiple specialized skills — re-check before declaring done:

- `expect(SchemaName.parse(body)).toBeTruthy();` for API responses.
- `getByRole > getByLabel > getByPlaceholder > getByText > getByTestId` for selectors.
- Single tag per test; `@destructive` is heaviest and wins — **shared/global state only** (locale, permissions, roles, access, flags, settings). Isolated own-data tests keep their importance tag. Any state-mutating test needs a revert hook.
- `z.strictObject()` (never `z.object()`), no `any`, no XPath, no `page.waitForTimeout(...)`.
- `process.env.*` for URLs/credentials; `enums/{area}/*` for paths/messages.
- Static data is `.ts` with `as const` exports — never `.json`.

## See Also

- **The Constitution** — always-loaded MUST/SHOULD/WON'T tables (the wrapper instructions for this set of files).
- **`common-tasks`** — codegen sub-router with prompt templates.
- **`debugging`** — failure-investigation half of the lifecycle (Phase 7 routes here on red).
- **`api-testing`** — deep skill for API work; owns Phase 1 (contract source) and Phase 7 (behaviour mismatch).
- **`refactor-values`** — deep skill for changing existing enum / static values.
- **`page-objects`**, **`selectors`**, **`playwright-cli`** — UI authoring chain.
- **`test-standards`**, **`data-strategy`**, **`type-safety`**, **`enums`**, **`config`**, **`fixtures`**, **`helpers`** — rest of the suite.
