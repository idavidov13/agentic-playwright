# Constitution Checklist

Mandatory gate. Before writing the report, walk this list against the three-dot diff and record a verdict for **every** applicable item: ✅ pass · ❌ fail · ➖ n/a (not touched by this branch). A failed item becomes a finding at the tier shown. Skip an item only if the branch genuinely doesn't touch that area — never because it "looks fine."

The list is derived from `CLAUDE.md`. It is the safety floor; the routed skills (Phase 3) add area-specific depth on top.

## How to use

Reproduce this table in your working notes (not necessarily in the final report) and fill the Verdict + Evidence columns. Evidence = `file:line` or a one-line reason. Any ❌ must appear in the report at its tier. If you mark an item ➖, you are asserting the diff does not touch it — be sure.

| #                              | Rule                                                                                                                                            | Tier if violated | Verdict | Evidence |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------- | -------- |
| **Imports & DI**               |
| 1                              | Spec files import `test`/`expect` from `fixtures/pom/test-options`, never `@playwright/test`                                                    | 🔴               |         |          |
| 2                              | No `new PageObject(page)` in tests — page objects come from fixtures                                                                            | 🔴               |         |          |
| **Type safety**                |
| 3                              | No `any` type anywhere in the diff                                                                                                              | 🔴               |         |          |
| 4                              | API schemas use `z.strictObject()`, never `z.object()`                                                                                          | 🔴               |         |          |
| 5                              | Schema mirrors the documented contract — no loosening (`.optional`/`.nullable`/`.passthrough`/widened types) added to swallow runtime surprises | 🔴               |         |          |
| 6                              | Exported functions have explicit return types                                                                                                   | 🟠               |         |          |
| 7                              | `process.env.*` uses a sanctioned pattern (`!` or `?? fallback`), values declared in `env/.env.example`                                         | 🟠               |         |          |
| **API tests**                  |
| 8                              | Response asserted exactly as `expect(SchemaName.parse(body)).toBeTruthy();`                                                                     | 🔴               |         |          |
| 9                              | Any test with 2+ API calls wraps each call in its own `test.step()`                                                                             | 🔴               |         |          |
| 10                             | Every status code in the spec has a test — passing, failing, or `test.skip` + `// FIXME: <ticket>` (no silent coverage drops)                   | 🔴               |         |          |
| 11                             | 400 tests do per-field omission + invalid-type `for...of` loops — not empty-body-only                                                           | 🟠               |         |          |
| **Sources of truth**           |
| 12                             | URLs/credentials from `process.env.*`; endpoint paths, routes, UI strings, storage-state paths from `enums/*` / `config/*` — nothing hardcoded  | 🔴               |         |          |
| 13                             | Repeated string values use enums, not inline literals                                                                                           | 🟡               |         |          |
| 14                             | Existing enum value / `test-data/static` value changes followed the `refactor-values` impact analysis (no stale references)                     | 🔴               |         |          |
| **Selectors & POM** (UI diffs) |
| 15                             | Selector priority respected: `getByRole` > `getByLabel` > `getByPlaceholder` > `getByText` > `getByTestId`                                      | 🟠               |         |          |
| 16                             | No XPath selectors                                                                                                                              | 🔴               |         |          |
| 17                             | Form/CRUD page objects have success, error, and validation-message selectors                                                                    | 🟠               |         |          |
| 18                             | JSDoc on action methods only — never on locator getters                                                                                         | 🟡               |         |          |
| 19                             | UI was explored with `playwright-cli` (not a substitute tool) before selectors were authored                                                    | 🟠               |         |          |
| **Assertions & waits**         |
| 20                             | Web-first assertions only (`expect(locator).toBeVisible()`) — no `page.waitForTimeout()` / hard waits                                           | 🔴               |         |          |
| 21                             | No magic numbers — timeouts/constants live in `config/` or `enums/`                                                                             | 🟡               |         |          |
| **Data strategy**              |
| 22                             | Happy-path data from Faker factories — no hardcoded test content strings                                                                        | 🟠               |         |          |
| 23                             | `test-data/static/**` files are `.ts` with `as const` — never `.json`                                                                           | 🔴               |         |          |
| 24                             | Invalid data placed correctly: universal arrays in `static/util/invalid-values`, curated sets in `static/{area}/*`                              | 🟡               |         |          |
| **Tags & structure**           |
| 25                             | Each test has exactly ONE tag; no tags on `test.describe()`; `@functional` not used                                                             | 🔴               |         |          |
| 26                             | State-mutating tests have `afterEach`/`afterAll` cleanup that reverts; shared-state mutators tagged `@destructive` only                         | 🔴               |         |          |
| 27                             | `test.step()` used with Given/When/Then for multi-step tests                                                                                    | 🟠               |         |          |
| **Hygiene**                    |
| 28                             | Passes ESLint + Prettier with no warnings (Phase 4 result)                                                                                      | 🔴               |         |          |
| 29                             | tsc clean for changed files (Phase 4 result, repo-wide pre-existing errors excluded)                                                            | 🔴               |         |          |
| 30                             | No explore-only / HTML-dump files committed; no scope creep beyond the ticket                                                                   | 🟡               |         |          |

## Output of this gate

A filled table. Carry every ❌ into the report at its tier, and let the count of unresolved ❌ inform the confidence score and verdict. If you couldn't evaluate an item (e.g. tests unrunnable for env), say so explicitly rather than marking it ✅.
