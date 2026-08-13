# Test Standards — Troubleshooting

## Test uses `{ tag: '@functional' }`

**Cause:** `@functional` is not a valid tag.
**Fix:** Replace with one of `@smoke` / `@sanity` / `@regression` / `@e2e` / `@api` — or `@destructive` if the test mutates shared state.

## Test uses `{ tag: ['@smoke', '@destructive'] }` or any other array

**Cause:** Combining tags is forbidden.
**Fix:** Collapse to a single tag. If the test mutates shared state, tag it **only** `@destructive` — that's the heaviest tag and always wins.

## Test imports `test` from `@playwright/test`

**Cause:** Wrong import source; the test won't see custom fixtures.
**Fix:** `import { expect, test } from '../../../fixtures/pom/test-options';`.

## Test uses `page.waitForTimeout(1000)`

**Cause:** Hard wait masks a timing issue.
**Fix:** Replace with `await expect(locator).toBeVisible()` (or another web-first matcher). If waiting for an API call, move the wait into the page-object action method as `page.waitForResponse(...)`.

## Test imports static data from a `.json` file

**Cause:** Pre-TS-migration code.
**Fix:** Create / rename the data file to `.ts` with a named `as const` export and import the named export directly — e.g. `import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';`.

## Test instantiates a page object via `new AppPage(page)`

**Cause:** Bypassing the fixture DI.
**Fix:** Consume through the fixture context — `async ({ appPage }) => { ... }`. If the page object isn't registered, see the `fixtures` skill.

## Tests pass in isolation but fail in the full suite

**Cause:** Shared mutable state between tests (common culprits: a test-global variable, a non-destructive test that mutates app state, missing `resetStorageState` in login tests).
**Fix:** Use `test.beforeEach` + factories for per-test data; `resetStorageState` for login-flow tests; if the test mutates shared state, retag as `@destructive` and add cleanup hooks (Phase 7).

## Destructive test leaked state between runs

**Cause:** Missing `test.afterEach()` / `test.afterAll()` cleanup.
**Fix:** Add the cleanup hook inside the `test.describe` block (Phase 7 pattern). The cleanup must be idempotent so it runs safely even after a failed test.

## Committed a file like `tests/app/explore.spec.ts` with `console.log(await page.content())`

**Cause:** Exploration artifact.
**Fix:** Delete before committing. Use `playwright-cli` (see the `playwright-cli` skill) for ad-hoc exploration — never commit debug specs.
