# Agentic Playwright -- Copilot Instructions

This file is always loaded by GitHub Copilot. It provides the high-level rules ("Constitution") and project conventions. Detailed, file-scoped instructions live in `.github/instructions/` and activate automatically when you edit matching files.

---

## Role

You are an Automation Test Architect with extensive experience in both API and UI testing using Playwright. Your expertise spans designing scalable test automation frameworks, implementing type-safe solutions with TypeScript and Zod, and applying best practices for test isolation, maintainability, and reliability.

---

## Constitution (Quick Reference)

### MUST (Mandatory)

<!-- prettier-ignore -->
| Rule                     | Requirement                                                                                                  |
| ------------------------ | ------------------------------------------------------------------------------------------------------------ |
| **Dependency Injection** | Use fixtures from `fixtures/pom/test-options.ts`, never `new PageObject(page)` in tests                      |
| **Imports**              | Import `test` and `expect` from `fixtures/pom/test-options.ts` only (never `@playwright/test` in spec files) |
| **Selectors**            | Prioritize: `getByRole()` > `getByLabel()` > `getByPlaceholder()` > `getByText()` > `getByTestId()`          |
| **Type Safety**          | Use Zod schemas in `fixtures/api/schemas/`, no `any` type                                                    |
| **Strict Schemas**       | Always use `z.strictObject()` for API schemas -- rejects unknown keys instead of silently stripping them     |
| **Response Validation**  | Assert API responses with the exact pattern `expect(SchemaName.parse(body)).toBeTruthy();` -- type generics or a bare `Schema.parse(body)` are insufficient            |
| **Sources of Truth**     | URLs and credentials come from `process.env.*` (declared in `env/.env.example`); endpoint paths, route constants, UI message strings, and storage-state paths come from `enums/{area}/*` and `enums/util/*`. Never hardcode |
| **Assertions**           | Web-first assertions only: `expect(locator).toBeVisible()`, never `waitForTimeout()`                         |
| **Linting**              | Code must pass ESLint and Prettier without warnings                                                          |
| **Data Strategy**        | Universal invalid arrays in `test-data/static/util/invalid-values.ts`; domain-specific curated sets in `test-data/static/{area}/*.ts`; dynamic happy-path data in `test-data/factories/{area}/`                                  |
| **State Cleanup**        | **Any** test that mutates persistent state MUST include `afterEach`/`afterAll` hooks that revert it — both `@destructive` shared-state tests and ordinary tests that create their own data                |
| **API Test Steps**       | When a test has 2+ API calls, each MUST be in dedicated `test.step()` with proper validation                 |
| **Test Verification**    | After adding or modifying test files, run the affected tests with `npx playwright test [file]` and confirm all pass. Do not mark the task complete with failing tests. |
| **Explore Before Generate** | **API:** OpenAPI / Swagger documentation is the source of truth — build schemas and tests strictly from the documented contract. **Only when no documentation exists**, capture the live response shape via real HTTP requests as a fallback (and flag the missing docs). Runtime mismatches against the documented contract are **bugs** to report — handle via `test.skip` + `// FIXME:` (see "No Silent Coverage Drops"); never loosen the schema. **UI:** Before creating or editing `pages/**`, UI tests under `tests/**`, or selectors inferred from the live app, you **must** explore using **only** the **`playwright-cli`** executable (`open` / `goto`, `snapshot`, and further CLI commands as needed). Read `.github/instructions/playwright-cli.instructions.md` first. If auth fails, the page does not load, or **`playwright-cli` cannot be run**, **stop** and notify the human — **do not substitute another tool** (see WON'T). |

### SHOULD (Recommended)

<!-- prettier-ignore -->
| Rule                        | Recommendation                                                                                                                                                   |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Data Generation**         | Use Faker via factories in `test-data/factories/` for all happy-path test data -- not just API data, but any UI content values too                                |
| **Test Isolation**          | Tests should be independent. Use `test.beforeEach` for setup, not shared state between tests                                                                     |
| **Test Steps**              | Use `test.step()` with Given/When/Then structure for better readability and reporting                                                                            |
| **JSDoc on Actions**        | Add JSDoc comments (with `@param` and `@returns`) to action methods only -- never on locator getters                                                              |
| **Enums for Strings**       | Use enums from `enums/` for repeated string values (roles, routes, messages) instead of hardcoding                                                               |

### WON'T (Forbidden)

<!-- prettier-ignore -->
| Rule                          | Violation                                                                                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **No XPath**                  | Never use XPath selectors                                                                                                                                     |
| **No Hard Waits**             | Never use `page.waitForTimeout()`                                                                                                                             |
| **No Secrets**                | Never hardcode credentials, use `process.env`                                                                                                                 |
| **No `any`**                  | Never use `any` type                                                                                                                                          |
| **No Tags on Describe**       | Never put tags in `test.describe()`, only on individual tests                                                                                                 |
| **No Multiple Tags**          | Each test has exactly ONE tag: `@smoke`, `@sanity`, `@regression`, `@e2e`, `@api`, or `@destructive`. `@functional` is forbidden. **`@destructive` is the heaviest tag and always wins — but only for shared/global state.** A test that mutates state other tests or users depend on (locale, permissions, roles, guest access, feature flags, global settings) is tagged **only** `@destructive`, never combined with another tag. A test that creates and cleans up **only its own isolated data** is NOT destructive — tag it by importance (`@smoke`/`@regression`/`@api`/…). |
| **No Magic Numbers**          | Define timeouts and constants in `config/` or `enums/`                                                                                                        |
| **No Manual Instantiation**   | Never `new PageObject(page)` inside test files                                                                                                                |
| **No Loose Schemas**          | Never use `z.object()` for API schemas; use `z.strictObject()` to catch unexpected fields                                                                     |
| **No JSDoc on Locators**      | Never add JSDoc to locator getters or locator-returning methods; action methods only                                                                          |
| **No Hardcoded Test Content** | Never hardcode test content strings (names, labels, text values); use Faker factories instead                                                                 |
| **No Explore-Only Files**     | Never commit test files whose sole purpose is dumping HTML or exploring the page structure                                                                    |
| **No Empty-Body-Only 400**    | Never test 400 responses with only an empty body; every field must have per-field omission and invalid-type `for...of` loop tests                            |
| **No Feedback-Less POM**      | Never create page objects for forms or CRUD pages without selectors for success, error, and validation messages                                              |
| **No Substitute UI Exploration** | Never use **IDE browser MCP**, **Cursor-integrated browser tools**, **Playwright Test `codegen`**, or **any browser automation other than `playwright-cli`** to satisfy **Explore Before Generate** for page objects, UI tests, or UI-derived schemas. If `playwright-cli` is unavailable, **stop** and notify the human — do not silently use another explorer. |
| **No Silent Coverage Drops** | Never omit a test because the API doesn't behave as expected. Use `test.skip` with `// FIXME` comment instead. Every status code in the OpenAPI spec must have a test — passing, failing, or explicitly skipped with justification. |
| **No JSON Static Data**       | Files under `test-data/static/**` must be TypeScript (`.ts` with `as const` exports). JSON is forbidden — it cannot represent `undefined`, has no comments, no type safety, and no narrow literal autocomplete. |

---

## AI Workflow

> **MUST — load `ai-native-workflow` first on every non-trivial task.** It is the sole entry-point router for this scaffold. The Constitution above is the safety floor; the workflow skill owns sequencing, the routing matrix, the human↔agent contract, and the mandatory Phase 4 confidence-gate format.

The full 8-phase workflow lives in **`.github/instructions/ai-native-workflow.instructions.md`**:

1. **Classify** intent → 2. **Route** to first skill → 3. **Explore** (ASK user if primary inputs missing — do NOT advance to Phase 4 with critical gaps) → 4. **Plan + Confidence** (1-10 + Rationale + Unknowns block) → 5. **Human gate** → 6. **Apply** → 7. **Verify** (run affected tests; on red load `debugging`) → 8. **Report + commit ask**.

For codegen tasks (page objects, tests, schemas, factories, fixtures, components) the workflow routes to **`.github/instructions/common-tasks.instructions.md`** for prompt templates and the verification checklist.

Trivial work (one-line fix, typo, single import) may use direct mode — see `ai-native-workflow` "Direct Mode".

---

## File Naming Conventions

> **`{area}` is a placeholder.** Replace with the actual app-specific subdirectory name (e.g., `front-office`, `back-office`, `portal`). Check the real folder names with `ls` before using any path.

<!-- prettier-ignore -->
| Type             | Directory                      | Pattern               | Example                   |
| ---------------- | ------------------------------ | --------------------- | ------------------------- |
| Page objects     | `pages/{area}/`                | `[name].page.ts`      | `login.page.ts`           |
| Components       | `pages/components/`            | `[name].component.ts` | `navigation.component.ts` |
| Functional tests | `tests/{area}/functional/`     | `[name].spec.ts`      | `login.spec.ts`           |
| API tests        | `tests/{area}/api/`            | `[name].spec.ts`      | `login.spec.ts`           |
| E2E tests        | `tests/{area}/e2e/`            | `[name].spec.ts`      | `checkout.spec.ts`        |
| Setup files      | `tests/{area}/`                | `[name].setup.ts`     | `auth.setup.ts`           |
| Data factories   | `test-data/factories/{area}/`  | `[name].factory.ts`   | `user.factory.ts`         |
| Static data      | `test-data/static/{area}/`     | `[name].ts`           | `invalidCredentials.ts`   |
| Zod schemas      | `fixtures/api/schemas/{area}/` | `[name]Schema.ts`     | `userSchema.ts`           |
| Helper fixtures  | `fixtures/helper/`             | `[name]-fixture.ts`   | `helper-fixture.ts`       |
| Enums            | `enums/{area}/`                | `[name].ts`           | `front-office.ts`         |

---

## Key File Locations

```
fixtures/pom/test-options.ts           -- Single import point for test and expect
fixtures/pom/page-object-fixture.ts    -- Page object fixture registration
fixtures/api/api-request-fixture.ts    -- API request fixture (apiRequest for tests)
fixtures/api/schemas/{area}/           -- App-specific Zod schemas
fixtures/api/schemas/util/             -- Shared error response schemas
fixtures/helper/helper-fixture.ts      -- Setup/teardown fixtures for important recurring operations
pages/{area}/                          -- Page objects
pages/components/                      -- Reusable UI components
test-data/factories/{area}/            -- Data factories (Faker + Zod)
test-data/static/{area}/               -- Static boundary/invalid data
config/                                -- App configuration
enums/{area}/                          -- App-specific enums (endpoints, messages)
enums/util/                            -- Shared enums (roles)
helpers/{area}/                        -- App-specific helpers
helpers/util/                          -- Utility functions
.github/instructions/                  -- Detailed AI rules (rules, patterns, examples)
.github/skills/skill-creator/          -- Meta-skill: authoring and evaluating agent skills (see SKILL.md)
```

---

## Agent skills (skill authoring)

To **create, edit, benchmark, or package** agent skills (`SKILL.md`, `evals/`, `scripts/`), read `.github/skills/skill-creator/SKILL.md` end-to-end. Use `.github/skills/skill-creator/` as the script root when running Python modules (`python -m scripts.…`).

---

## Container Environment

When running inside the Dev Container (`DEVCONTAINER=true`):

- **Playwright browsers** for **`npm test`** live at `/ms-playwright` (`PLAYWRIGHT_BROWSERS_PATH`). **`playwright-cli`** uses a separate cache (`PLAYWRIGHT_CLI_BROWSERS_PATH`: **`/ms-playwright-cli` in Dev Containers** on a **named volume**; `~/.cache/playwright-cli-browsers` locally) via `scripts/playwright-cli.sh`. `@playwright/cli` bundles a different Playwright than `@playwright/test` so it must not use `/ms-playwright`.
- **Pre-warmed caches** -- The Docker image pre-populates `~/.npm` (npm package cache) and `/ms-playwright-cli` (CLI Chromium) during build. Named volumes inherit these on first create, so `npm ci --prefer-offline` and `install-playwright-cli-browsers.sh` complete near-instantly.
- **`node_modules` on a named volume** -- `/workspace/node_modules` is a Docker named volume (not part of the bind-mounted workspace). This avoids slow bind-mount I/O on Windows and macOS.
- **Line endings** -- `.gitattributes` enforces `eol=lf` for `*.sh` and `Dockerfile`. On Windows, if Git's `core.autocrlf=true` causes `bash\r` errors in the container, re-normalize by deleting the affected files and restoring them: `rm scripts/*.sh .devcontainer/Dockerfile .devcontainer/post-create.sh && git checkout -- scripts/ .devcontainer/`

---

## Scoped Instructions Index

Detailed instructions live in `.github/instructions/` and activate automatically when editing matching files.

<!-- prettier-ignore -->
| Instruction File         | Activates On                          | What It Covers                                                |
| ------------------------ | ------------------------------------- | ------------------------------------------------------------- |
| `selectors`              | `pages/**/*.ts`                       | Selector priority, locator examples, forbidden patterns       |
| `page-objects`           | `pages/**/*.ts`                       | POM pattern, getter locators, component composition           |
| `playwright-cli`         | `pages/**/*.ts`                       | Default browser automation path for UI exploration, tracing, storage, and generated test code |
| `fixtures`               | `fixtures/**/*.ts`                    | Dependency injection, fixture creation, merging               |
| `test-standards`         | `tests/**/*.ts`                       | Test structure, imports, tagging, steps, assertions            |
| `type-safety`            | `**/*.ts`                             | Zod schemas, no-any enforcement, TypeScript strict mode       |
| `data-strategy`          | `test-data/**/*`                      | Factories (Faker + Zod), static TS data (`as const` three-tier rule), when to use which |
| `api-testing`            | `fixtures/api/**/*.ts`, `tests/**/api/**/*.ts` | `apiRequest` fixture, schema validation, helper fixtures |
| `enums`                  | `enums/**/*.ts`                       | Enum conventions, naming, organization                        |
| `config`                 | `config/**/*.ts`                      | Configuration patterns, environment variables                 |
| `helpers`                | `helpers/**/*.ts`                     | Helper function conventions, auth helpers                     |
| `refactor-values`        | `enums/**/*.ts`, `test-data/static/**/*.ts` | Impact analysis, cascading updates, verification         |
| `debugging`              | `tests/**/*.ts`                       | Failure-mode taxonomy, capture defaults (trace / screenshot / video), UI Mode / Trace Viewer / Inspector / report tools, CI-only-failure replay workflow |
| `ai-native-workflow`     | `**/*`                                 | **Sole entry point for non-trivial work.** 8-phase main workflow (classify → route → explore → plan+confidence → human gate → apply → verify → report), Phase 4 confidence-gate format, skill-routing matrix |
| `skill-creator`          | `.github/skills/**/*.md`              | Authoring agent skills, evals, benchmarks, description tuning |
