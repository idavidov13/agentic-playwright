---
applyTo: 'pages/**/*.ts,tests/**/*.ts,fixtures/**/*.ts,test-data/**/*'
---

# AI Prompt Templates for Agentic Playwright

Codegen sub-router. Owns prompt templates per artifact type and the post-generation verification checklist. Plugs into `ai-native-workflow` Phase 2 (Route) for codegen intents.

For the 8-phase workflow see `ai-native-workflow/SKILL.md`. For worked examples and troubleshooting see this skill's `references/`.

## Critical

These rules are unique to template usage. **All other rules** (selectors, waits, types, Zod strictness, response validation, tags, fixtures, JSDoc, no-XPath, no-hardcoded-strings, etc.) live in the **Constitution** (the always-loaded MUST/SHOULD/WON'T tables wrapping these instructions) and the **leaf skills** (`api-testing`, `page-objects`, `selectors`, `test-standards`, `data-strategy`, `type-safety`, `fixtures`, `enums`). Re-read the Constitution + the matching leaf skill's Critical block **before** generating from any template here.

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

Open the template section for your category (see [Prompt Templates](#prompt-templates)). Copy the block, replace every `[PLACEHOLDER]` and every `{area}` with concrete values. Leave no unreplaced placeholders in the final prompt.

### Phase 3: Load the specialized skill for the deep rules

The templates intentionally stay shallow. When the task needs more than the template's bullets — full status-code coverage, selector exploration rules, fixture composition patterns — load the specialized skill listed in Phase 1 and follow it end-to-end. **Do not reimplement that skill's rules inline.** Re-read the Constitution + the leaf skill's Critical block before writing code.

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

Quick reference for where each artifact lives:

| Task               | Key Files                      | Primary Tool / Fixture   |
| ------------------ | ------------------------------ | ------------------------ |
| Add page object    | `pages/{area}/`                | `page-object-fixture.ts` |
| Add API schema     | `fixtures/api/schemas/{area}/` | Zod                      |
| Add test           | `tests/{area}/`                | `test-options.ts`        |
| Add API test       | `tests/{area}/api/`            | `apiRequest` fixture     |
| Add setup/teardown | `fixtures/helper/`             | `helper-fixture.ts`      |
| Add data factory   | `test-data/factories/{area}/`  | Faker + Zod              |
| Add component      | `pages/components/`            | N/A                      |

### Page Object Tasks

> **Important:** Before generating page objects, read the `playwright-cli` instructions and run **`playwright-cli` in the terminal** (`goto`, `snapshot`, etc.). **Do not** use IDE browser MCP or any substitute — orchestrator rule **No Substitute UI Exploration**. If the CLI cannot run, stop and notify the human.

#### Add a New Page Object (With Exploration)

```
Create a new page object for [PAGE NAME].

First, run `ls pages/` to find the correct area subdirectory (e.g., front-office, back-office).

Then use playwright-cli to navigate to [URL] and explore the page to discover:
- Element roles, labels, and accessible names
- Form field structure and validation
- Button names and available actions
- Any dynamic content or loading states

Then generate the page object with:
- File location: pages/{area}/[name].page.ts  (use real area name from ls)
- Accurate semantic locators based on exploration
- NO JSDoc on locator getters/methods — names are self-documenting
- JSDoc with @param and @returns on action methods only
- Registration in fixtures/pom/page-object-fixture.ts
```

#### Add a New Page Object (Without Exploration)

Use this when you already know the exact element structure:

```
Create a new page object for [PAGE NAME] with the following elements:
- [List of elements/locators needed]
- [Actions the page should perform]

Requirements:
- File location: pages/{area}/[name].page.ts  (run `ls pages/` first to find real area name)
- Use semantic locators (getByRole > getByLabel > getByTestId)
- NO JSDoc on locator getters/methods
- JSDoc with @param and @returns on action methods only
- Register in fixtures/pom/page-object-fixture.ts
- Follow the pattern from pages/app/app.page.ts
```

#### Add Locators to Existing Page

```
Add the following locators to [PAGE_NAME] page object:
- [Element 1]: [description]
- [Element 2]: [description]

Use getByRole() as the primary selector strategy.
Add getter methods following the existing pattern.
```

#### Add Action Method to Page Object

```
Add an action method to [PAGE_NAME] page object:
- Method name: [methodName]
- Purpose: [what it does]
- Parameters: [list parameters]
- Wait for: [API response or element state]

Include proper return type and JSDoc comment.
```

### Test Tasks

> **Important:** Before generating tests, navigate through the user flow to understand the actual steps and expected outcomes.

#### Create a Functional Test

Functional tests verify one feature or behaviour in isolation. Each test covers a single thing.

```
Create a functional test for [FEATURE]:
- Location: tests/{area}/functional/[name].spec.ts  (run `ls tests/` first)
- Import from fixtures/pom/test-options.ts
- Use factory data from test-data/factories/{area}/ — never hardcode test content
- Tag with exactly ONE tag: @smoke | @sanity | @regression — or @destructive if the test modifies shared state (destructive overrides and is the only tag)
- Structure with test.describe and test.step (Given/When/Then)
- Use beforeEach for navigation/setup

Test scenarios:
1. [Scenario 1]
2. [Scenario 2]
```

#### Create an E2E Test

E2E tests chain multiple features together in a single test that mirrors a complete real user journey.

```
Create an E2E test for [USER JOURNEY].

First, run `ls tests/` to find the correct area subdirectory.

Then navigate through the full flow at [STARTING_URL] to discover:
- The complete sequence of steps from start to finish
- Elements and state at each milestone
- Final expected state

Then generate the test with:
- Location: tests/{area}/e2e/[name].spec.ts  (use real area name from ls)
- A SINGLE test covering the entire journey (not one test per step)
- Factory data from test-data/factories/{area}/
- Tag: @e2e
- Steps that chain naturally: setup → action → action → ... → final assertion
```

#### Add Data-Driven Tests

```
Add data-driven tests to [TEST FILE] for [SCENARIO]:
- Use static data from test-data/static/{area}/[file].ts  (run `ls test-data/static/` first)
- Import the named `as const` export; never redeclare inline
- Loop outside test blocks to generate individual tests
- Each test should have descriptive name including test data

Test data structure (test-data/static/{area}/[file].ts):

export const CASES = [
    { description: '', input: '', expected: '' },
] as const;
```

#### Add API Test

```
Create an API test for [ENDPOINT]:
- HTTP method: [GET|POST|PUT|DELETE|PATCH]
- Endpoint: [/api/path]
- Request body schema: [describe fields and their types]
- Expected response schema: [describe fields]

FIRST: Source the contract. If OpenAPI / Swagger documentation exists, build
schemas and tests strictly from it. Only explore the live endpoint if no
documentation is available. Then build a coverage plan by listing every status
code from the spec for this endpoint, stating what test will cover each.
Present the plan before generating code.

Requirements:
- Create Zod schema in fixtures/api/schemas/{area}/ (run `ls fixtures/api/schemas/` first; use z.strictObject())
- Use the apiRequest fixture (destructured from test context)
- Validate every response with: expect(SchemaName.parse(body)).toBeTruthy();
- Pull endpoint paths from enums/{area}/* (e.g., ApiEndpoints.PRODUCTS) — never hardcode
- Pull URLs and tokens from process.env.* — never hardcode
- Tag with @api
- For endpoints with a body (POST/PUT/PATCH), include comprehensive validation:
  - Empty body test ({})
  - Each required field omitted individually (destructure + rest)
  - Each field tested with type-inappropriate values via for...of loop,
    importing the universal arrays from test-data/static/util/invalid-values.ts
    (INVALID_STRING_VALUES, INVALID_NUMBER_VALUES, etc.) — never redefine inline
  - Field-specific boundary / range violations may stay inline in the spec
  - Use factory data (generateX()) for the valid base payload
- For endpoints with path params: invalid format data-driven loop (numeric, boolean-like, special chars, SQL injection)
- For endpoints with auth: 401 (no token) and 403 (wrong role) tests
- For all endpoints: at least one 405 test with unsupported HTTP method
- Any test that would fail due to API bug: test.skip + /* eslint-disable playwright/no-skipped-test */ + // FIXME: <ticket-url>, never omit
```

### API Schema Tasks

> **Important:** Source schemas from OpenAPI / Swagger documentation when it exists. Only capture the live response shape as a fallback for undocumented endpoints. See the `api-testing` skill (Phase 1).

#### Create a New Zod Schema (From Documentation — Default)

```
Create a Zod schema for [ENDPOINT] based on the OpenAPI / Swagger documentation.

First, run `ls fixtures/api/schemas/` to find the correct area subdirectory.

Then generate the schema from the documented contract:
- Location: fixtures/api/schemas/{area}/[name]Schema.ts  (use real area name from ls)
- Use z.strictObject() — never z.object()
- Field types, required/optional, nullability, and nested shapes exactly match the spec
- Proper Zod validators (z.email(), z.uuid(), z.url(), z.int(), etc.)
- Export both the schema and the inferred TypeScript type
- Spell out the response envelope (success / message / data / errors) as a z.strictObject per the OpenAPI spec — schemas are a 1:1 mirror of the documented contract; do not invent a factory helper. If the envelope repeats across 3+ endpoints in one domain, extract `fixtures/api/schemas/{area}/_envelope.ts` and compose via .extend(...)
- Follow the pattern from fixtures/api/schemas/app/userSchema.ts

If a runtime response disagrees with the schema later, that is a bug —
report it and wrap the test with test.skip + // FIXME: <ticket-url>.
Do NOT loosen the schema to match buggy behavior.
```

#### Create a New Zod Schema (Fallback — No Documentation Available)

Use this only when no OpenAPI / Swagger documentation exists for the endpoint.

```
Create a Zod schema for [ENDPOINT]. No documentation exists for this endpoint,
so we are capturing the observed contract.

First, run `ls fixtures/api/schemas/` to find the correct area subdirectory.

Then make a request to [API_URL/endpoint] to discover:
- Actual response structure and field names
- Data types for each field
- Optional vs required fields
- Nested objects or arrays
- Error response formats

Then generate the schema with:
- Location: fixtures/api/schemas/{area}/[name]Schema.ts  (use real area name from ls)
- Use z.strictObject() — never z.object()
- Accurate field types based on the actual response
- Proper Zod validators (z.email(), z.uuid(), z.url(), z.int(), etc.)
- Exported TypeScript type
- Flag missing documentation to the team as a follow-up
```

#### Add Fields to Existing Schema

```
Add the following fields to [SCHEMA_NAME]:
- [field1]: [type with validation rules]
- [field2]: [type with validation rules]

Update the corresponding TypeScript type export.
Keep z.strictObject(); do not weaken to z.object().
```

### Data Factory Tasks

#### Create a New Data Factory

```
Create a data factory for [DATA TYPE]:
- Location: test-data/factories/{area}/[name].factory.ts  (run `ls test-data/factories/` first)
- Use @faker-js/faker for data generation
- Validate output with Zod schema from fixtures/api/schemas/
- Support overrides parameter for customization
- Support seed option for reproducibility

Fields to generate:
- [field1]: [faker method to use]
- [field2]: [faker method to use]
```

#### Add Static Test Data

Before adding static data, pick the right tier per the three-tier rule (see the `api-testing` skill, Phase 6, and the `data-strategy` skill):

1. **Universal type-mismatch arrays** (wrong type for any field of a given primitive type) → already centralised in `test-data/static/util/invalid-values.ts`. Import from there; do not create new ones.
2. **Domain-specific curated invalid values** (invalid email formats, password policy violations, invalid locales, forbidden enum values, etc.) → live under `test-data/static/{area}/` — this is the tier a new static file usually belongs to.
3. **Field-specific boundary / range values** (e.g., out-of-range for a `1..5` number) → may stay inline in the spec when used in exactly one place.

Static data files are TypeScript only (`.ts` with `as const` exports). Never `.json`. The file may export only literal values — no runtime imports, no functions, no Faker.

```
Create static test data for [PURPOSE] at the correct tier:
- Tier: [domain-specific → test-data/static/{area}/ | universal type-mismatch → already in test-data/static/util/invalid-values.ts]
- Location: test-data/static/{area}/[name].ts  (run `ls test-data/static/` first)
- Use for: [domain-specific invalid values | boundary testing | edge cases]

Data structure (as const literal values only, no logic):

export const [CATEGORY] = [
    { description: '', value: '' },
] as const;
```

### Fixture Tasks

#### Add a New Page Object Fixture

```
Create a new fixture for [PAGE OBJECT]:
- Location: fixtures/pom/page-object-fixture.ts (add to existing)
- Fixture name: [fixtureName]
- Purpose: [what page object it provides]

Requirements:
- Add type to FrameworkFixtures
- Add fixture with `async ({ page }, use) => { await use(new PageObject(page)); }`
- No separate fixture file needed for page objects
```

#### Add a Helper Fixture (Setup/Teardown)

```
Create a helper fixture for [PURPOSE]:
- Location: fixtures/helper/helper-fixture.ts (add to existing)
- Fixture name: [fixtureName]
- Purpose: [what precondition it sets up and tears down]

Requirements:
- Add return type to HelperFixtures
- Use apiRequest from plain-function.ts for API calls
- Implement setup → use() → teardown pattern
- Setup: Create precondition via API before the test
- Yield: Pass created data to the test via use()
- Teardown: Clean up after the test (runs even on failure)
- Already merged into test-options.ts (no extra registration needed)
- Promote to a helper fixture only when the same setup/teardown is reused across 3+ spec files (see the api-testing skill, Phase 8)
```

#### Add a New Fixture Category

```
Create a new fixture category for [PURPOSE]:
- Location: fixtures/[category]/[name]-fixture.ts
- Fixture name: [fixtureName]
- Purpose: [what it provides]

Requirements:
- Export test using base.extend<FixtureType>()
- Export the fixture types
- Add cleanup logic if needed
- Merge into fixtures/pom/test-options.ts via mergeTests()
```

### Component Tasks

#### Add a Reusable Component

```
Create a component object for [COMPONENT NAME] (e.g., header, modal, sidebar):
- Location: pages/components/[name].component.ts
- Elements: [list of elements]
- Actions: [list of actions]

The component should be composable into page objects.
Follow the pattern from pages/components/navigation.component.ts.
```

## See Also

- **The Constitution** — MUST/SHOULD/WON'T tables in the always-loaded wrapper instructions are the safety floor for every artifact generated from a template here.
- **`ai-native-workflow`** — owns the 8-phase workflow; Phase 2 routes codegen intents to this skill.
- **`api-testing`** — deep rules for API tests + schemas; load before using **Add API Test** or **Create a New Zod Schema** templates.
- **`page-objects`**, **`selectors`**, **`playwright-cli`** — the UI authoring chain; load before using Page Object Tasks templates.
- **`test-standards`** — spec structure, tagging, web-first assertions, data-driven loops; load before using any Test Tasks template.
- **`data-strategy`** — factory + static-data three-tier rule; load before using Data Factory Tasks.
- **`fixtures`**, **`helpers`** — DI patterns and helper-fixture promotion; load before using Fixture Tasks.
- **`type-safety`** — Zod 4 validators + the `expect(Schema.parse(body)).toBeTruthy()` rule; load before any schema work.
- **`debugging`** — load on Phase 4 verification red.
- **`refactor-values`** — load when a template would change an existing enum value or static-data row.
