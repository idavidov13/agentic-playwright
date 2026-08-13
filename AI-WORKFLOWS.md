# AI Task Workflows — Step-by-Step Playbook

A canonical, drift-proof reference for **how each task is executed** in this scaffold. Every common flow — build an API suite, write functional tests from a ticket, an E2E journey, debug a failure, and more — is laid out as an explicit step sequence so you (and the agent) follow the **same path every time**.

> **How to read this.** Each step cites its owning skill and phase (e.g. `api-testing · P5`). This file is the **map**; the `.claude/skills/**` (and mirrored `.cursor/`, `.github/`) skills remain the **authoritative source of the deep rules**. If this map and a skill ever disagree, the skill wins — and that's a bug to fix here. `{area}` is a placeholder (e.g. `front-office`); always resolve it with `ls` first, never guess.

---

## Contents

- [The Universal Spine (every task)](#the-universal-spine-every-task)
- [The Confidence Gate](#the-confidence-gate)
- [Routing — intent → first skill](#routing--intent--first-skill)
- [Flow 1 — API test suite for a controller / resource group](#flow-1--api-test-suite-for-a-controller--resource-group)
- [Flow 2 — Functional tests from a ticket](#flow-2--functional-tests-from-a-ticket)
- [Flow 3 — E2E test suite](#flow-3--e2e-test-suite)
- [Flow 4 — Debug a failing or flaky test](#flow-4--debug-a-failing-or-flaky-test)
- [Flow 5 — Page object (with exploration)](#flow-5--page-object-with-exploration)
- [Flow 6 — Zod schema for an endpoint](#flow-6--zod-schema-for-an-endpoint)
- [Flow 7 — Data factory & static data](#flow-7--data-factory--static-data)
- [Flow 8 — Fixture (page object & helper)](#flow-8--fixture-page-object--helper)
- [Flow 9 — Refactor an enum value / static data](#flow-9--refactor-an-enum-value--static-data)
- [Flow 10 — Add an enum / endpoint / message](#flow-10--add-an-enum--endpoint--message)
- [Flow 11 — Add an env var / config value](#flow-11--add-an-env-var--config-value)
- [Flow 12 — Add a helper / reusable component](#flow-12--add-a-helper--reusable-component)
- [Anti-Drift Guardrails](#anti-drift-guardrails)
- [Command Cheat-Sheet](#command-cheat-sheet)

---

## The Universal Spine (every task)

Every non-trivial task runs through these 8 phases in order. Owned by `ai-native-workflow`.

| #   | Phase             | What happens                                                                        | Gate                                                  |
| --- | ----------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------- |
| 1   | Classify intent   | Map the request to an intent class (codegen / edit / refactor / debug / explore).   | —                                                     |
| 2   | Route             | Pick the first skill from the routing table. Codegen → `common-tasks`.              | —                                                     |
| 3   | Explore           | Gather evidence (OpenAPI, `playwright-cli`, `ls`). **Missing primary input → ASK.** | Do not advance with critical gaps.                    |
| 4   | Plan + Confidence | Emit the proposal block (scope, trade-offs, confidence 1-10, rationale, unknowns).  | Confidence **< 5 → do not emit; return to P3 + ASK**. |
| 5   | Human gate        | Wait for approve / modify / reject. Reject → back to P3 with the stated gap.        | No code before approval.                              |
| 6   | Apply             | Make the edits per the leaf skill's rules; re-check every loaded Critical block.    | —                                                     |
| 7   | Verify            | Lint + run the affected tests. Red → load `debugging`.                              | Never suppress failures or bump timeouts.             |
| 8   | Report + commit   | List files changed, line counts, lint status. **Ask before committing.**            | Commit only on request.                               |

**Trivial work** (one-line fix, typo, single import) may use Direct Mode — but still verify the user's premise (the defect actually exists) before editing.

### The Confidence Gate

Phase 4's proposal **must** carry a 1-10 confidence. The number tells you what to do next:

| Confidence | Meaning                                                                                         | Action                                                                                                             |
| ---------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **< 5**    | Exploration is incomplete — you're guessing.                                                    | **Do NOT emit a plan. Return to P3 and ASK** for the missing input (URL, OpenAPI source, area folder, field list). |
| **5–7**    | Real trade-off with known unknowns.                                                             | Emit the plan with explicit unknowns; proceed only if the human accepts at this level.                             |
| **≥ 8**    | Full evidence in hand.                                                                          | Proceed normally.                                                                                                  |
| **≥ 9**    | Explicit spec match, no `{area}` ambiguity, no missing enum/env/credential, no untested branch. | Proceed.                                                                                                           |

**Proposal block format:**

```
## Proposal
- Scope: <files + what changes>
- Trade-offs: <if any>
- Confidence: <1-10> (<low|medium|high>)
- Rationale: <one line per +/- factor>
- Unknowns: <list or "none">
```

### Routing — intent → first skill

| You want to…                                  | First skill             | Then chains to                                            |
| --------------------------------------------- | ----------------------- | --------------------------------------------------------- |
| Add tests for `POST /api/...`                 | `api-testing`           | `data-strategy`, `enums`, `type-safety`, `debugging`      |
| Add a page object for X                       | `page-objects`          | `selectors`, `playwright-cli`, `enums`, `fixtures`        |
| "Generate a prompt for…" / "How do I add Y?"  | `common-tasks`          | the matching specialized skill                            |
| Test failing / flaky                          | `debugging`             | `api-testing`, `selectors`, `fixtures`, `refactor-values` |
| Rename an enum / change a static value        | `refactor-values`       | `enums` or `data-strategy` → `debugging`                  |
| Create a factory for X                        | `data-strategy`         | `type-safety`, `api-testing`                              |
| Wire a setup helper / helper fixture          | `helpers` or `fixtures` | `api-testing` P8                                          |
| Add an env var / config / utility URL         | `config`                | `enums`, `type-safety`                                    |
| Add an enum / endpoint / message              | `enums`                 | `playwright-cli` for live-text verification               |
| Refactor a Zod schema / convert `any` → typed | `type-safety`           | `api-testing`                                             |
| Add a spec file / tagging / structure Q       | `test-standards`        | `data-strategy`, `api-testing`, `page-objects`            |

---

## Flow 1 — API test suite for a controller / resource group

**Use when:** building full coverage for one resource group with multiple endpoints and methods (e.g. `GET/POST /products`, `GET/PUT/DELETE /products/:id`).
**Chain:** `api-testing` → `type-safety` · `data-strategy` · `enums` · `test-standards` · `debugging`

| Step | Action                                                                                                                                                               | Skill · Phase                              | Gate / Output                                    |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------ |
| 1    | Classify → route to `api-testing`.                                                                                                                                   | `ai-native` · P1–P2                        | —                                                |
| 2    | **Source the contract.** OpenAPI / Swagger is the source of truth. No docs? ASK, or fall back to a live request and flag it.                                         | `api-testing` · P1                         | No contract & can't obtain → **ASK** (conf < 5). |
| 3    | **Build the coverage plan**: list every endpoint × method × status code from the spec; state the test for each. **Present before coding.**                           | `api-testing` · P5                         | Human approves the plan.                         |
| 4    | Define one `z.strictObject()` schema per response; spell out the envelope; infer types. Repeated envelope (3+) → `_envelope.ts`.                                     | `api-testing` · P2 · `type-safety` · P2–P3 | Schemas mirror the documented contract 1:1.      |
| 5    | Endpoint paths → `enums/{area}/*` (`ApiEndpoints.*`); URLs / tokens → `process.env.*`. Never hardcode.                                                               | `api-testing` · Critical · `enums`         | —                                                |
| 6    | Happy-path payloads from Faker factories; negative inputs from the three tiers.                                                                                      | `data-strategy` · P2–P3                    | —                                                |
| 7    | Write tests with the **`apiRequest` fixture**; one `test.describe` per method + path; `beforeAll`/`afterAll` for shared resources.                                   | `api-testing` · P3, P5                     | —                                                |
| 8    | Each response: `expect(SchemaName.parse(body)).toBeTruthy();`. Multi-call tests → each call in its own `test.step`.                                                  | `api-testing` · P3–P4                      | —                                                |
| 9    | **Cover the full status matrix** per endpoint: 200/201, 400/422, 401, 403, 404, 405, 409, 204 — plus every code the spec lists.                                      | `api-testing` · P5                         | Every status code has a test.                    |
| 10   | **Per-field negative coverage**: empty body, each required field omitted, each field with invalid types (`for...of` over `INVALID_*`). Fuzz path params (mandatory). | `api-testing` · P6                         | No empty-body-only 400s.                         |
| 11   | Behavior ≠ spec? Write the test as the spec says, `test.skip` it + `// FIXME: <ticket-url>`. **Never loosen the schema.**                                            | `api-testing` · P7                         | No silent coverage drops.                        |
| 12   | Same setup/teardown reused in 3+ files? Promote to a helper fixture — otherwise use `apiRequest` directly.                                                           | `api-testing` · P8                         | —                                                |
| 13   | Tag every test `@api` (single tag).                                                                                                                                  | `test-standards` · P3                      | —                                                |
| 14   | Run the suite; red → `debugging`. Then report + ask to commit.                                                                                                       | `ai-native` · P7–P8                        | Zero failures before "done".                     |

---

## Flow 2 — Functional tests from a ticket

**Use when:** a ticket / acceptance criteria describes one feature's behaviours to verify in isolation.
**Chain:** `test-standards` → `page-objects` · `selectors` · `playwright-cli` · `data-strategy`

| Step | Action                                                                                                                                   | Skill · Phase                          | Gate / Output                  |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ------------------------------ |
| 1    | Classify → route to `test-standards` (+ UI chain if new screens are involved).                                                           | `ai-native` · P1–P2                    | —                              |
| 2    | Split the ticket into discrete behaviours → **one functional test per behaviour**.                                                       | `test-standards` · intro               | —                              |
| 3    | Missing URL / area / unclear acceptance criteria? **ASK before planning.**                                                               | `ai-native` · P3                       | Confidence < 5 → ASK.          |
| 4    | New screen/elements? Explore the live app with **`playwright-cli`** (`goto`, `snapshot`). No substitutes.                                | `page-objects` · P2 · `selectors` · P2 | Exploration evidence captured. |
| 5    | Plan: list scenarios, the tag for each, and data needs. Present.                                                                         | `ai-native` · P4–P5                    | Human approves.                |
| 6    | Create/extend the page object: semantic locators (`getByRole` > `getByLabel` > …), **including success / error / validation selectors**. | `page-objects` · P3–P5 · `selectors`   | No feedback-less POM.          |
| 7    | Content values from Faker factories; curated invalid sets from static `.ts`.                                                             | `data-strategy` · P2–P3                | No hardcoded test content.     |
| 8    | Write the spec: import from `test-options.ts`; `describe` + `beforeEach`; `test.step` (Given/When/Then).                                 | `test-standards` · P2, P4              | —                              |
| 9    | One tag per test: `@smoke` \| `@sanity` \| `@regression`. Web-first assertions only.                                                     | `test-standards` · P3, P5              | No `waitForTimeout`.           |
| 10   | Run the affected file; red → `debugging`. Report + ask to commit.                                                                        | `test-standards` · P9                  | Zero failures.                 |

---

## Flow 3 — E2E test suite

**Use when:** verifying a complete multi-feature user journey end to end (e.g. login → add to cart → checkout → confirm).
**Chain:** `test-standards` → `page-objects` · `playwright-cli` · `data-strategy`

| Step | Action                                                                                              | Skill · Phase                           | Gate / Output         |
| ---- | --------------------------------------------------------------------------------------------------- | --------------------------------------- | --------------------- |
| 1    | Classify → route to `test-standards` (E2E type) + UI chain.                                         | `ai-native` · P1–P2                     | —                     |
| 2    | **Walk the full journey** in `playwright-cli` to discover each milestone, state, and final outcome. | `page-objects` · P2                     | Journey mapped.       |
| 3    | Plan: **one test for the whole journey** (not one per step); list milestones + data.                | `test-standards` · intro                | Human approves.       |
| 4    | Build/extend page objects & components for each milestone.                                          | `page-objects` · P3–P5                  | —                     |
| 5    | Write a single `@e2e` test chaining setup → action → action → … → final assertion.                  | `test-standards` · P3–P4                | One tag: `@e2e`.      |
| 6    | Factory data for journey inputs; web-first assertions throughout.                                   | `data-strategy` · `test-standards` · P5 | —                     |
| 7    | Run; flaky → `debugging` (re-run 5× after the fix). Report + ask to commit.                         | `debugging` · P6                        | Stable across 5 runs. |

---

## Flow 4 — Debug a failing or flaky test

**Use when:** any test fails, flakes, or behaves unexpectedly. **Never** suppress — investigate first, fix second.
**Chain:** `debugging` → `api-testing` (P7) · `selectors` · `fixtures` · `refactor-values`

| Step | Action                                                                                                                    | Skill · Phase    | Gate / Output       |
| ---- | ------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------------------- |
| 1    | Read the failure message fully (error type, expected vs received, the failing line).                                      | `debugging` · P1 | —                   |
| 2    | Classify the failure mode (see table below).                                                                              | `debugging` · P2 | Mode identified.    |
| 3    | Reproduce locally — run the single spec, deterministic.                                                                   | `debugging` · P3 | Reproduced.         |
| 4    | Investigate with the **right tool** for the mode (see table).                                                             | `debugging` · P4 | Root cause located. |
| 5    | Fix at the **root cause** — no `try/catch` on `expect`, no timeout bumps, no silent `.skip`.                              | `debugging` · P5 | —                   |
| 6    | Re-run; for flake fixes, run **5× consecutively**.                                                                        | `debugging` · P6 | Green & stable.     |
| 7    | Red in CI, green locally? Replay CI conditions: `ENVIRONMENT=ci CI=1 npx playwright test <file> --workers=1 --retries=0`. | `debugging` · P7 | —                   |

**Failure mode → tool / fix:**

| Failure mode                           | Likely cause                                  | Tool / next step                                                             |
| -------------------------------------- | --------------------------------------------- | ---------------------------------------------------------------------------- |
| `TimeoutError` on action/assertion     | Wrong/again-changed locator, state not ready  | Trace Viewer (`npm run report`), UI Mode (`test:ui`)                         |
| `ZodError` from `Schema.parse(body)`   | Response ≠ documented contract (schema drift) | If real bug → `test.skip` + `// FIXME` (`api-testing` · P7); else fix schema |
| Strict-mode violation (multiple match) | Locator not specific enough                   | `selectors` (scope the locator)                                              |
| Locator not found                      | Element/markup changed                        | Re-explore with `playwright-cli`; update page object                         |
| "fixture is undefined"                 | Missing registration / wrong import           | `fixtures`                                                                   |
| Passes alone, fails in suite           | Shared-state / ordering coupling              | `test-standards` · P9 (independence), `@destructive` cleanup                 |
| Assertion drift after a value change   | Enum / static value changed                   | `refactor-values`                                                            |

---

## Flow 5 — Page object (with exploration)

**Use when:** a new screen needs a page object, or an existing one needs locators/actions.
**Chain:** `page-objects` → `selectors` · `playwright-cli` · `enums` · `fixtures`

| Step | Action                                                                                                                                                                                                                | Skill · Phase                          |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| 1    | Verify prerequisites; `ls pages/` to resolve `{area}`.                                                                                                                                                                | `page-objects` · P1                    |
| 2    | **Explore the live app with `playwright-cli`** (`goto`, `snapshot`). No IDE browser / codegen / substitutes — if the CLI can't run, **stop and tell the human**.                                                      | `page-objects` · P2 · `selectors` · P2 |
| 3    | Plan the page's test coverage (which elements, which actions, feedback messages).                                                                                                                                     | `page-objects` · P3                    |
| 4    | Build the class: get-accessor locators by priority (`getByRole` > `getByLabel` > `getByPlaceholder` > `getByText` > `getByTestId`); **JSDoc on action methods only**; include success / error / validation selectors. | `page-objects` · P4 · `selectors`      |
| 5    | Register the page object in `fixtures/pom/page-object-fixture.ts`.                                                                                                                                                    | `page-objects` · P5 · `fixtures`       |
| 6    | Consume from tests via the fixture (`async ({ appPage }) => …`) — never `new PageObject(page)`.                                                                                                                       | `page-objects` · P6                    |

---

## Flow 6 — Zod schema for an endpoint

**Use when:** an endpoint needs a typed, validated response/request schema.
**Chain:** `api-testing` (P2) → `type-safety`

| Step | Action                                                                                                                                                         | Skill · Phase                           |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| 1    | Source from OpenAPI / Swagger (default). No docs → capture live shape as a fallback and flag it.                                                               | `api-testing` · P1                      |
| 2    | `ls fixtures/api/schemas/` to resolve `{area}`.                                                                                                                | `type-safety` · P2                      |
| 3    | Build with **`z.strictObject()`** (never `z.object()`); top-level validators (`z.uuid()`, `z.email()`, `z.int()`, …); spell out the envelope per the contract. | `type-safety` · P2                      |
| 4    | Export the schema **and** the inferred type (`zOutput`). Reuse `util/errorResponseSchema.ts` for 400/401/403/404.                                              | `type-safety` · P3                      |
| 5    | Validate at runtime in the test with `expect(SchemaName.parse(body)).toBeTruthy();`.                                                                           | `type-safety` · P4 · `api-testing` · P3 |
| 6    | Runtime disagrees later? That's a **bug** → `test.skip` + `// FIXME`. Never loosen the schema.                                                                 | `api-testing` · P7                      |

---

## Flow 7 — Data factory & static data

**Use when:** you need dynamic happy-path data, or curated invalid/boundary inputs.
**Chain:** `data-strategy` → `type-safety` · `api-testing`

| Step | Action                                                                                                                                                                                                          | Skill · Phase        |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| 1    | Classify the value: dynamic happy-path → **factory**; reusable invalid set → **static**; one-off boundary → **inline**.                                                                                         | `data-strategy` · P1 |
| 2    | Factory: `test-data/factories/{area}/[name].factory.ts` — Faker + Zod-validated output, `overrides` + `seed`.                                                                                                   | `data-strategy` · P2 |
| 3    | Static (the three-tier rule): universal type-mismatch → `test-data/static/util/invalid-values.ts` (import, never redefine); domain-specific → `test-data/static/{area}/*.ts`; field-specific boundary → inline. | `data-strategy` · P3 |
| 4    | Static files are **`.ts` with `as const`** exports only — never `.json`, no logic.                                                                                                                              | `data-strategy` · P3 |
| 5    | Consume: factories for payloads/content; static via named imports in `for...of` loops.                                                                                                                          | `data-strategy` · P4 |

---

## Flow 8 — Fixture (page object & helper)

**Use when:** wiring a page object into DI, or sharing setup/teardown across tests.
**Chain:** `fixtures` (+ `helpers`) → `api-testing` (P8)

| Step | Action                                                                                                                              | Skill · Phase                        |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 1    | Classify: page-object fixture, helper (setup/teardown) fixture, or a new fixture category.                                          | `fixtures` · P1                      |
| 2    | Page-object fixture → add to `fixtures/pom/page-object-fixture.ts` + type in `FrameworkFixtures`.                                   | `fixtures` · P3–P4                   |
| 3    | Helper fixture → `fixtures/helper/helper-fixture.ts`: setup → `await use(data)` → teardown (runs on failure).                       | `fixtures` · P6 · `api-testing` · P8 |
| 4    | **Promote to a helper fixture only when the same setup/teardown is reused across 3+ files** — otherwise call `apiRequest` directly. | `api-testing` · P8                   |
| 5    | New category → `base.extend<…>()` then **merge into `test-options.ts`** via `mergeTests()`.                                         | `fixtures` · P5                      |

---

## Flow 9 — Refactor an enum value / static data

**Use when:** changing the string value of an enum member, renaming an enum key, or editing existing `test-data/static/**`.
**Chain:** `refactor-values` → `enums` or `data-strategy` → `debugging`

| Step | Action                                                                                  | Skill · Phase          | Gate / Output        |
| ---- | --------------------------------------------------------------------------------------- | ---------------------- | -------------------- |
| 1    | **Find all consumers first** — search every usage before touching anything.             | `refactor-values` · P1 | Full impact list.    |
| 2    | Categorize impact (value change vs key rename vs assertion-coupled string).             | `refactor-values` · P2 | —                    |
| 3    | Make **all** changes atomically (definition + every consumer + assertions in one pass). | `refactor-values` · P3 | No stale references. |
| 4    | Verify: TypeScript compiles, affected tests pass; red → `debugging`.                    | `refactor-values` · P4 | Green.               |

---

## Flow 10 — Add an enum / endpoint / message

**Use when:** introducing a repeated string constant (endpoint path, UI message, route, storage-state path).
**Chain:** `enums` → `playwright-cli` (for live-text verification)

| Step | Action                                                                                       | Skill · Phase |
| ---- | -------------------------------------------------------------------------------------------- | ------------- |
| 1    | Confirm the value is app-defined & repeated (belongs in an enum, not `config`/static data).  | `enums` · P1  |
| 2    | Pick the home: app-specific → `enums/{area}/*`; shared → `enums/util/*`. New file vs extend. | `enums` · P2  |
| 3    | Name it: `PascalCase` enum, `SCREAMING_SNAKE_CASE` members.                                  | `enums` · P3  |
| 4    | **Verify message strings against the real app** with `playwright-cli` — never guess UI text. | `enums` · P4  |
| 5    | Add JSDoc + export; consume via the enum everywhere (no hardcoded duplicates).               | `enums` · P5  |

---

## Flow 11 — Add an env var / config value

**Use when:** a test/fixture needs a new URL, credential, or environment-driven setting.
**Chain:** `config` → `enums` · `type-safety`

| Step | Action                                                                                           | Skill · Phase                      |
| ---- | ------------------------------------------------------------------------------------------------ | ---------------------------------- |
| 1    | Understand env loading (`ENVIRONMENT` → `env/.env.*` via `playwright.config.ts`).                | `config` · P1                      |
| 2    | Decide where it belongs: URL/credential/env-setting → `config`; endpoint path/message → `enums`. | `config` · P2                      |
| 3    | Declare it in `env/.env.example` (and the real env file).                                        | `config` · P3                      |
| 4    | Add a config property with JSDoc **only if warranted**; otherwise read `process.env.*` directly. | `config` · P4                      |
| 5    | Consume via `process.env.*` (`!` non-null or `??` fallback per `type-safety`) — never hardcode.  | `config` · P5 · `type-safety` · P6 |

---

## Flow 12 — Add a helper / reusable component

**Use when:** a reusable plain function (no fixture lifecycle), or a composable UI component.
**Chain:** `helpers` / `page-objects` · `selectors`

| Step | Action                                                                                                      | Skill · Phase                |
| ---- | ----------------------------------------------------------------------------------------------------------- | ---------------------------- |
| 1    | **Helper**: no Playwright fixture lifecycle needed → `helpers/{area}/` (app) or `helpers/util/` (generic).  | `helpers` · P1–P2            |
| 2    | Define typed signature + JSDoc; read env via `process.env.*`; if it makes API calls, validate with Zod.     | `helpers` · P3–P5            |
| 3    | **Component**: `pages/components/[name].component.ts`, semantic locators, composable into page objects.     | `page-objects` · `selectors` |
| 4    | Need the fixture lifecycle (setup/teardown) instead? Use a **helper fixture** (Flow 8), not a plain helper. | `fixtures` · P6              |

---

## Anti-Drift Guardrails

The rules most often skipped under time pressure — and the one that catches each. These are hard stops (`CLAUDE.md` Constitution).

| Drift you might make                                                      | The rule that prevents it                                                                                                   |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Guessing a selector / UI text / folder / enum value                       | **Explore first** (`playwright-cli` for UI, OpenAPI for API) or **ASK**. Never invent.                                      |
| Emitting a plan you're not sure of                                        | Confidence **< 5 → don't emit; ASK** for the missing input.                                                                 |
| `curl` the API then write a schema that matches reality                   | Schemas come from the **documented contract**; runtime mismatch is a **bug**, not a fix.                                    |
| Loosening a schema to make a test pass                                    | `test.skip` + `// FIXME: <ticket-url>`. Never weaken the contract.                                                          |
| `z.object()` for an API schema                                            | Always **`z.strictObject()`** — catches unexpected fields.                                                                  |
| Skipping `expect(Schema.parse(body)).toBeTruthy()`                        | Mandatory for every API response — type generics alone are insufficient.                                                    |
| Empty-body-only 400 test                                                  | Per-field omission **and** per-field invalid-type loops are required.                                                       |
| Two tags / `@functional` / tag on `describe`                              | **Exactly one** tag per test; `@destructive` wins — shared/global state only.                                               |
| `@destructive` for isolated own-data test                                 | Reserve `@destructive` for shared/global state (locale, permissions, roles, flags); isolated CRUD keeps its importance tag. |
| Any state-mutating test with no cleanup                                   | Required `afterEach`/`afterAll` that reverts state — destructive **and** isolated.                                          |
| `page.waitForTimeout(...)` / XPath / `any`                                | Web-first assertions only; semantic locators only; typed only.                                                              |
| `new PageObject(page)` in a test                                          | Consume via the fixture (`async ({ appPage }) => …`).                                                                       |
| Hardcoded URL / token / endpoint                                          | `process.env.*` for URLs & credentials; `enums/{area}/*` for paths & messages.                                              |
| `.json` static data                                                       | Static data is **`.ts` with `as const`** only.                                                                              |
| Marking a task done with failing tests                                    | Run the affected tests; green before "done"; red → `debugging`.                                                             |
| Suppressing a failure (try/catch on `expect`, raise timeout, silent skip) | Fix the **root cause**; `debugging` flow.                                                                                   |

---

## Command Cheat-Sheet

| Command                                                                  | Purpose                                 |
| ------------------------------------------------------------------------ | --------------------------------------- |
| `npm test`                                                               | All non-destructive tests (parallel).   |
| `npm run test:smoke` / `:sanity` / `:regression` / `:api` / `:e2e`       | Run one tag.                            |
| `npm run test:destructive`                                               | Destructive suite only (`--workers=1`). |
| `npx playwright test <file>`                                             | Run a single spec.                      |
| `npm run test:ui`                                                        | UI Mode — time-travel debugging.        |
| `npm run test:debug`                                                     | Inspector — step through a test.        |
| `npm run test:headed`                                                    | Watch the browser run.                  |
| `npm run report`                                                         | Open the HTML report / Trace Viewer.    |
| `ENVIRONMENT=ci CI=1 npx playwright test <file> --workers=1 --retries=0` | Replay CI conditions locally.           |
| `npm run lint` / `lint:fix` / `format`                                   | ESLint / autofix / Prettier.            |
| `npm run check:skills-drift` / `check:skills-references`                 | Validate AI-rules integrity.            |

---

_This playbook mirrors the scaffold's skills (`.claude/skills/**`, mirrored to `.cursor/` and `.github/`). The skills own the deep rules and examples; this file is the orchestration map that keeps every task on the same path._
