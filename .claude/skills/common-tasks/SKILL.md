---
name: common-tasks
description: Copy-paste AI prompt templates for common Playwright scaffold development tasks — adding page objects, functional/E2E/API tests, Zod schemas, factories, fixtures, and components. Use when the user asks "how do I add a ...", "give me a prompt for ...", "create a new [page object | test | schema | factory | fixture | component]", or when bootstrapping a new scaffold artifact and wanting a standardized starting prompt. This skill is a routing layer; for the deep rules of each task category load the matching skill directly — page-objects / selectors / playwright-cli for UI locators, api-testing for API tests and schemas, fixtures / helpers for fixtures, data-strategy for factories and static data, test-standards for test structure and tags, type-safety for TypeScript + Zod, enums for endpoint enums.
author: Ivan Davidov
---

# AI Prompt Templates for Agentic Playwright

Codegen sub-router. Owns prompt templates per artifact type and the post-generation verification checklist. Plugs into `ai-native-workflow` Phase 2 (Route) for codegen intents.

For the 8-phase workflow see `ai-native-workflow/SKILL.md`. For worked examples and troubleshooting see this skill's `references/`.

## Critical

These rules are unique to template usage. **All other rules** (selectors, waits, types, Zod strictness, response validation, tags, fixtures, JSDoc, no-XPath, no-hardcoded-strings, etc.) live in the **`CLAUDE.md` Constitution** and the **leaf skills** (`api-testing`, `page-objects`, `selectors`, `test-standards`, `data-strategy`, `type-safety`, `fixtures`, `enums`). Re-read the Constitution + the matching leaf skill's Critical block **before** generating from any template here.

- **Resolve `{area}` first.** Every template contains `{area}` as a placeholder. Run the matching `ls` (`ls pages/`, `ls tests/`, `ls fixtures/api/schemas/`, `ls test-data/factories/`, `ls test-data/static/`, `ls enums/`) and substitute the real folder name **before** filling the template. Do not guess.
- **Templates are starters, not substitutes.** Each template is a 10-15 line scaffold. The leaf skill listed for the category owns the deep rules — load it and follow it end-to-end. Never reimplement a leaf skill's rules inline in your prompt.
- **Walk the verification checklist** (below) after generating. It is the canonical post-codegen audit; the leaf skills point here for it.

## Instructions

### Phase 1: Identify the task category and resolve paths

Match the user's request to one row, then run the `ls` commands the row's templates need.

| Category                | Template section                      | Specialized skill(s)                          | `ls` to run before filling                           |
| ----------------------- | ------------------------------------- | --------------------------------------------- | ---------------------------------------------------- |
| Page object / component | Page Object Tasks                     | `page-objects`, `selectors`, `playwright-cli` | `ls pages/`                                          |
| Functional / E2E test   | Test Tasks                            | `test-standards`, `data-strategy`             | `ls tests/`, `ls test-data/factories/`               |
| API test                | Test Tasks → Add API Test             | `api-testing`, `test-standards`               | `ls tests/`, `ls fixtures/api/schemas/`, `ls enums/` |
| Zod response schema     | API Schema Tasks                      | `api-testing`, `type-safety`                  | `ls fixtures/api/schemas/`                           |
| Data factory            | Data Factory Tasks                    | `data-strategy`, `type-safety`                | `ls test-data/factories/`                            |
| Static test data        | Data Factory Tasks → Static Test Data | `data-strategy`, `api-testing`                | `ls test-data/static/`                               |
| Fixture (POM / helper)  | Fixture Tasks                         | `fixtures`, `helpers`                         | (no path placeholder)                                |
| UI component            | Component Tasks                       | `page-objects`, `selectors`                   | (no path placeholder)                                |

### Phase 2: Select and customize the matching prompt template

Open the theme file for your category from the [Prompt Templates](#prompt-templates) index below, copy the block, and replace every `[PLACEHOLDER]` and every `{area}` with concrete values. Leave no unreplaced placeholders in the final prompt.

### Phase 3: Load the specialized skill for the deep rules

The templates intentionally stay shallow. When the task needs more than the template's bullets — full status-code coverage, selector exploration rules, fixture composition patterns — load the specialized skill listed in Phase 1 and follow it end-to-end. **Do not reimplement that skill's rules inline.** Re-read the `CLAUDE.md` Constitution + the leaf skill's Critical block before writing code.

### Phase 4: Verify with the checklist, then run the affected tests

Walk every box. Then run the affected tests; on red, load `debugging`.

#### Verification Checklist

After generating code, confirm each box:

- [ ] Imports are from `fixtures/pom/test-options.ts` (never `@playwright/test` in specs)
- [ ] Paths, credentials, and endpoints come from `process.env.*` and `enums/{area}/*` — nothing hardcoded
- [ ] Locators use `getByRole` / `getByLabel` / `getByTestId` — no XPath
- [ ] No `any` types
- [ ] No hard waits (`waitForTimeout`)
- [ ] No JSDoc on locator getters/methods (JSDoc only on action methods)
- [ ] Tests use `test.step` with Given/When/Then structure
- [ ] Each test has exactly ONE tag from `@smoke`, `@sanity`, `@regression`, `@e2e`, `@api`, `@destructive` (never `@functional`, never multiple)
- [ ] Tags live on individual tests, not on `test.describe()` blocks
- [ ] Tests that mutate **shared/global** state (locale, permissions, roles, guest access, feature flags, global settings) are tagged **only** `@destructive`; tests that create + clean up **only their own data** keep their importance tag
- [ ] **Any** state-mutating test (destructive or isolated) has an `afterEach`/`afterAll` hook that reverts what it wrote
- [ ] Happy-path test data uses factories; curated invalid values come from `test-data/static/util/` or `test-data/static/{area}/`
- [ ] Zod schemas use `z.strictObject()` — never `z.object()`
- [ ] API response validation uses `expect(SchemaName.parse(body)).toBeTruthy();`
- [ ] API tests with request bodies include empty-body + per-field omission + per-field invalid-type `for...of` loops (universal arrays imported from `test-data/static/util/invalid-values.ts`)
- [ ] **Coverage audit:** Every status code in the OpenAPI spec has a matching test (or `test.skip` + `// FIXME`)
- [ ] **Path parameter tests:** Endpoints with path params have the invalid-format data-driven loop
- [ ] **405 tests:** At least one unsupported HTTP method test per endpoint
- [ ] **Auth matrix:** Endpoints with `security` have both 401 (no token) and 403 (wrong role) tests
- [ ] **Behavior mismatches:** Any divergence from spec uses `test.skip` + `// FIXME: <ticket-url>`, never silent omission
- [ ] No explore-only or throwaway test files committed

#### Run the affected tests (mandatory)

```bash
npx playwright test tests/{area}/[type]/[name].spec.ts   # specific file
npx playwright test --grep @smoke                        # by tag
npm test                                                 # all non-destructive
```

**Failure protocol:** Read the error → load `debugging` (failure-mode taxonomy + right Playwright tool per failure: UI Mode, Trace Viewer, Inspector, HTML report) → fix the root cause (no `try/catch` on `expect`, no timeout bumps, no silent `.skip`) → re-run; for flake fixes, 5x consecutively.

## Prompt Templates

Split by theme under `templates/` so the agent loads only the slice it needs — open the file matching your Phase 1 category, copy the block, and replace every `[PLACEHOLDER]` and `{area}` with concrete values.

- [Page object templates](references/templates/page-objects.md) — new page object (with / without exploration), add locators, add action method
- [Test templates](references/templates/tests.md) — functional, E2E, data-driven, and API tests
- [API schema templates](references/templates/api-schemas.md) — Zod schema from docs, fallback capture, add fields
- [Data templates](references/templates/data.md) — Faker factory and static test data
- [Fixture templates](references/templates/fixtures.md) — page-object fixture, helper fixture, fixture category
- [Component templates](references/templates/components.md) — reusable UI component

## See Also

- **`CLAUDE.md`** — Constitution (MUST/SHOULD/WON'T tables) is the safety floor for every artifact generated from a template here.
- **`ai-native-workflow`** — owns the 8-phase workflow; Phase 2 routes codegen intents to this skill.
- **`api-testing`** — deep rules for API tests + schemas; load before using **Add API Test** or **Create a New Zod Schema** templates.
- **`page-objects`**, **`selectors`**, **`playwright-cli`** — the UI authoring chain; load before using Page Object Tasks templates.
- **`test-standards`** — spec structure, tagging, web-first assertions, data-driven loops; load before using any Test Tasks template.
- **`data-strategy`** — factory + static-data three-tier rule; load before using Data Factory Tasks.
- **`fixtures`**, **`helpers`** — DI patterns and helper-fixture promotion; load before using Fixture Tasks.
- **`type-safety`** — Zod 4 validators + the `expect(Schema.parse(body)).toBeTruthy()` rule; load before any schema work.
- **`debugging`** — load on Phase 4 verification red.
- **`refactor-values`** — load when a template would change an existing enum value or static-data row.
- **`references/examples.md`** — three end-to-end multi-skill chains using the templates.
- **`references/troubleshooting.md`** — common pitfalls when filling templates and how to fix.
