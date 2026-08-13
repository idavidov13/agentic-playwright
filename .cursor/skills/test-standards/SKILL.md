---
name: test-standards
description: Spec file conventions for the Playwright scaffold — imports from test-options.ts, test file structure (describe / beforeEach / test / test.step), single-tag rule, functional vs E2E vs API vs setup test types, data-driven test loops against TS static data, web-first assertions, destructive-test cleanup, and test independence. Use when creating a new spec file, adding tests to an existing spec, deciding which test type or tag to use, writing data-driven loops, wiring destructive cleanup, or reviewing a test for compliance. For the deep API test-coverage matrix and negative-testing patterns see the api-testing skill; for factories and static data see the data-strategy skill; for prompt templates see the common-tasks skill; for page object usage from tests see the fixtures and page-objects skills.
author: Ivan Davidov
---

# Test Standards

## Critical

- **Imports:** Import `test` and `expect` from `fixtures/pom/test-options.ts`. **NEVER** from `@playwright/test` in spec files.
- **Single-tag rule:** Each test has **exactly one** tag chosen from `@smoke` | `@sanity` | `@regression` | `@e2e` | `@api` | `@destructive`. **NEVER** combine tags. **NEVER** use `@functional`. **NEVER** put tags on `test.describe()` blocks.
- **`@destructive` is the heaviest tag and always wins — but only for shared/global state.** A test that mutates state other tests or users depend on (locale, permissions, roles, guest access, feature flags, global settings) is tagged **only** `@destructive`. A test that creates and deletes **only its own data** is isolated, not destructive — tag it by importance (`@smoke` / `@sanity` / `@regression` / `@e2e` / `@api`).
- **Every state-mutating test** must have `test.afterEach()` or `test.afterAll()` cleanup that reverts the change — both `@destructive` shared-state tests and isolated tests that write their own data.
- **Web-first assertions only** (`await expect(locator).toBeVisible()`, `.toHaveText()`, `.toBeEnabled()`, `.toHaveCount(...)`, etc.). **NEVER** `page.waitForTimeout(...)`.
- **Use `test.step()` for Given/When/Then structure** when a test has more than one distinct phase (setup, action, assertion).
- **Tests must be independent.** No ordering dependencies, no shared mutable state across tests.
- **NEVER** commit explore-only or debug test files (`.spec.ts` containing `console.log(await page.content())`, temporary probes, etc.).
- **Static test data is imported from `.ts` modules** (`test-data/static/**/*.ts`) via named `as const` exports. **NEVER** `.json`.
- **Dynamic happy-path data** comes from Faker factories (`test-data/factories/{area}/`); universal type-mismatch arrays from `test-data/static/util/invalid-values.ts`; domain-specific curated sets from `test-data/static/{area}/*.ts`. See the `data-strategy` skill.
- **Page objects are consumed via the fixture** (`async ({ appPage }) => ...`). **NEVER** `new PageObject(page)` inside a test.
- **After adding or modifying a test file, run the affected tests and confirm zero failures** before finishing the task.

## Test File Location and Type

> **`{area}` is a placeholder.** Before creating or referencing any path below, run `ls tests/` to discover the real subdirectory names in this repo (e.g., `front-office`, `back-office`) and use those instead.

| Test Type  | Directory                  | What it covers                                         |
| ---------- | -------------------------- | ------------------------------------------------------ |
| Functional | `tests/{area}/functional/` | One feature or behaviour in isolation                  |
| API        | `tests/{area}/api/`        | API contracts and response validation                  |
| E2E        | `tests/{area}/e2e/`        | A complete multi-feature user journey in a single test |
| Setup      | `tests/{area}/`            | Auth or precondition setup (`.setup.ts`)               |

**Functional vs E2E distinction:**

- A **functional test** isolates and verifies a single behaviour (e.g., "adding a todo updates the count"). Each test covers one thing.
- An **E2E test** chains multiple features together in one test that mirrors a real user journey from start to finish (e.g., add items → complete → filter → clear → verify final state). An E2E file typically contains one or a few high-level scenario tests.

## Instructions

### Phase 1: Classify the test type and pick the location

Determine whether the work is a **functional**, **E2E**, **API**, or **setup** test, then run `ls tests/` to resolve `{area}` and place the file in `tests/{area}/<type>/[name].spec.ts` (or `tests/{area}/[name].setup.ts` for setup). Never guess the area.

### Phase 2: Write the imports and file skeleton

Every spec file starts with:

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('Feature Name', () => {
    test.beforeEach(async ({ appPage }) => {
        await appPage.openHomePage();
    });

    test(
        'should do expected behavior',
        { tag: '@smoke' },
        async ({ appPage }) => {
            // ...
        }
    );
});
```

- Imports come from `fixtures/pom/test-options.ts`, **not** `@playwright/test`.
- `test.describe(...)` groups related tests; the describe name has **no tag**.
- `test.beforeEach(...)` handles navigation and per-test setup (see Phase 7 for destructive cleanup and Phase 6 for `resetStorageState`).

### Phase 3: Tag the test (single-tag rule)

Each test gets **exactly one** tag. Pick the right one:

| Tag            | Used for                                                                                                                                                                  |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@smoke`       | Critical path functional tests, run first and frequently                                                                                                                  |
| `@sanity`      | Key functionality verification                                                                                                                                            |
| `@regression`  | Full regression coverage of a single behaviour                                                                                                                            |
| `@e2e`         | End-to-end multi-feature user journey tests                                                                                                                               |
| `@api`         | API contract and schema validation tests                                                                                                                                  |
| `@destructive` | Mutates **shared/global** state (locale, permissions, roles, guest access, feature flags, global settings) — excluded from `npm test`, run via `npm run test:destructive` |

**`@destructive` overrides any other importance tag — for shared/global state mutation only.** If a test would otherwise be `@smoke` but changes global settings, it is tagged **only** `@destructive`. A test that creates and cleans up **only its own data** is isolated, not destructive — keep its importance tag (`@smoke`/`@regression`/`@api`/…).

```typescript
// CORRECT
test('should login successfully', { tag: '@smoke' }, async ({ appPage }) => {
    /* ... */
});
test('should validate cart flow', { tag: '@e2e' }, async ({ checkoutPage }) => {
    /* ... */
});
test('should return user profile', { tag: '@api' }, async ({ apiRequest }) => {
    /* ... */
});
test(
    'should delete all users',
    { tag: '@destructive' },
    async ({ apiRequest }) => {
        /* ... */
    }
);

// WRONG -- @functional is not a valid tag
test('should login', { tag: '@functional' }, async ({ appPage }) => {
    /* ... */
});

// WRONG -- combining tags is forbidden
test(
    'should delete all users',
    { tag: ['@regression', '@destructive'] },
    async () => {
        /* ... */
    }
);

// WRONG -- tag belongs on the test, not the describe
test.describe('Feature @smoke', () => {
    /* ... */
});
```

### Phase 4: Structure the test body with `test.step`

Use `test.step()` to split the test into Given / When / Then blocks. This produces readable HTML reports and makes debugging faster.

```typescript
test(
    'should show error for invalid login',
    { tag: '@regression' },
    async ({ appPage }) => {
        await test.step('GIVEN user is on the login page', async () => {
            await expect(appPage.loginButton).toBeVisible();
        });

        await test.step('WHEN user enters invalid credentials', async () => {
            // generateLoginCredentials() is illustrative -- build the factory
            // via the data-strategy skill or use process.env.* + a known-bad password.
            const { email, password } = generateLoginCredentials();
            await appPage.login(email, password);
        });

        await test.step('THEN error message is displayed', async () => {
            await expect(appPage.errorMessage).toBeVisible();
        });
    }
);
```

For API tests with multiple calls, `test.step` is **mandatory** — see the `api-testing` skill (Phase 4).

### Phase 5: Use web-first assertions

Web-first assertions auto-wait and retry until the condition is met or a timeout elapses. Never use hard waits.

```typescript
// CORRECT -- web-first assertions
await expect(locator).toBeVisible();
await expect(locator).toHaveText('Expected text');
await expect(locator).toBeEnabled();
await expect(locator).toHaveCount(3);

// FORBIDDEN -- hard waits mask real timing issues
await page.waitForTimeout(1000);
```

If a response must be awaited, use `page.waitForResponse(...)` inside a page-object action method, not inside the spec.

### Phase 6: Handle setup / teardown and storage state

- Use `test.beforeEach()` for per-test navigation and setup.
- Use `test.afterEach()` for per-test cleanup when fixtures don't handle it.
- Use the `resetStorageState` fixture when testing login/logout flows so each test starts unauthenticated:

```typescript
test.beforeEach(async ({ resetStorageState, appPage }) => {
    await resetStorageState();
    await appPage.openHomePage();
});
```

For API-driven setup/teardown reused across many files, see the `api-testing` skill (Phase 8, helper-fixture rule of thumb).

### Phase 7: Handle destructive tests

**`@destructive` is reserved for shared/global state.** A test is destructive only when it mutates state that lives **outside** the test and that other tests, users, or sessions depend on. Concretely:

- changing the **locale** / language / region
- granting or **removing permissions, roles, or guest access**
- toggling **feature flags** or global settings / configuration
- mutating **shared seed data** every test reads (e.g. "delete all users", resetting a global catalog)

**Counter-example — NOT destructive.** A test that creates its **own** record, asserts on it, then deletes **only that record** in cleanup is _isolated_, not destructive. It touches no state another test depends on. Tag it by importance (`@smoke` / `@regression` / `@api` / …) — never `@destructive`. It still needs a cleanup hook (see below), but it runs in the parallel suite.

**Cleanup hook is required for any state-mutating test.** Both `@destructive` shared-state tests and isolated own-data tests **MUST** use `test.afterEach()` or `test.afterAll()` to revert what they wrote:

```typescript
test.describe('admin data management', () => {
    test.afterEach(async ({ apiRequest }) => {
        // REQUIRED: Revert state changes made by the test.
        // ApiEndpoints.RESET_DATA is illustrative -- use whatever reset
        // endpoint your app provides, defined in enums/{area}/*.ts.
        await apiRequest({
            method: 'POST',
            url: ApiEndpoints.RESET_DATA,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    });

    test(
        'should delete all inactive users',
        { tag: '@destructive' },
        async ({ apiRequest }) => {
            // Test that modifies shared state
        }
    );
});
```

**Execution rules:**

- **Excluded from `npm test`** — the base command uses `--grep-invert @destructive` to keep destructive tests out of the parallel suite.
- **Tag-specific commands** (`test:smoke`, `test:regression`, `test:api`, etc.) use `--grep` to match their own tag. Because each test has **exactly one** tag, a `@destructive` test only runs under `npm run test:destructive` — not under `test:smoke`, `test:regression`, etc.
- **Dedicated command** — `npm run test:destructive` runs only destructive tests with `--workers=1` for sequential execution.

### Phase 8: Data-driven tests

Loop **outside** test blocks to generate individual test cases. Static data is imported from `.ts` modules via named `as const` exports.

```typescript
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
    test(
        `should show error for ${description}`,
        { tag: '@regression' },
        async ({ appPage }) => {
            await appPage.login(email, password);
            await expect(appPage.errorMessage).toBeVisible();
        }
    );
}
```

For **universal** invalid-value loops (wrong type for any `string`/`number`/etc. field) import from `test-data/static/util/invalid-values.ts` (`INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, etc.). Full three-tier rule in the `data-strategy` skill.

### Phase 9: Verify test independence and run

Tests must be **independent** — no test may depend on the outcome or side-effects of another test. Use fixtures and `beforeEach` for shared setup.

After adding or modifying a test file:

```bash
# Run the specific spec file
npx playwright test tests/app/functional/login.spec.ts

# Run by tag (exactly one tag match since tags never combine)
npx playwright test --grep @smoke

# Run the destructive suite
npm run test:destructive
```

Do not finish until the added/modified tests pass consistently. Do not suppress failures.

## See Also

- **`api-testing`** skill — full API test coverage matrix, `test.step` requirements for multi-call tests, per-field negative-testing patterns, helper-fixture promotion rule (Phase 8).
- **`data-strategy`** skill — Faker + Zod factories, three-tier static data rule, universal invalid-value arrays, TS-only policy.
- **`fixtures`** skill — DI pattern, `test-options.ts` merge layer, page-object fixture registration.
- **`page-objects`** skill — POM class structure, action methods, component composition, fixture registration.
- **`selectors`** skill — exploration-first workflow, locator priority, feedback / validation message selectors.
- **`common-tasks`** skill — copy-paste prompt templates for creating spec files of each type.
- **`refactor-values`** skill — safe workflow for changing enum values or static data used in assertions.
- **`debugging`** skill — failure-mode taxonomy and the right Playwright tool (UI Mode, Trace Viewer, Inspector) when a test fails or behaves unexpectedly during Phase 9 verification.
- **`references/examples.md`** — four worked spec patterns (functional smoke, data-driven regression, destructive with cleanup, E2E multi-feature journey).
- **`references/troubleshooting.md`** — common test-standards pitfalls (`@functional`, tag arrays, wrong imports, hard waits, JSON data, manual instantiation, parallel collisions, destructive leaks, committed explore files).
