# Test Templates

Prompt templates for functional, E2E, data-driven, and API tests. The `test-standards`, `data-strategy`, and `api-testing` skills own the deep rules. Resolve `{area}` with `ls tests/` first.

> **Important:** Before generating tests, navigate through the user flow to understand the actual steps and expected outcomes.

## Create a Functional Test

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

## Create an E2E Test

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

## Add Data-Driven Tests

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

## Add API Test

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
