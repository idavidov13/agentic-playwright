---
name: test-standards
description: Use when creating or editing a spec file under tests/**, choosing a test type or tag, writing a data-driven loop, or wiring cleanup for a state-mutating test. Not for API coverage matrices (see `api-testing`) or factories and static data (see `data-strategy`).
---

# Test Standards

## Critical

- Import `test` and `expect` from `fixtures/pom/test-options.ts`, never from `@playwright/test`.
- Each test has **exactly one** tag from `@smoke`, `@sanity`, `@regression`, `@e2e`, `@api`, `@destructive`. Never `@functional`, never a tag array, never a tag on `test.describe()`.

    ```typescript
    // CORRECT
    test('should login', { tag: '@smoke' }, async ({ appPage }) => {});
    // WRONG
    test('should login', { tag: ['@smoke', '@e2e'] }, async () => {});
    ```

- `@destructive` is the heaviest tag and always wins, but only for shared/global state (locale, permissions, roles, guest access, feature flags, global settings, shared seed data). A test that creates and removes only its own data keeps its importance tag.
- **Every state-mutating test** has a `test.afterEach()` or `test.afterAll()` hook that reverts what it wrote, and the hook succeeds after a failed test.
- Web-first assertions only: `await expect(locator).toBeVisible()`, `.toHaveText()`, `.toHaveCount()`. Never `page.waitForTimeout()`.

    ```typescript
    // CORRECT
    await expect(appPage.username).toBeVisible();
    // WRONG
    await page.waitForTimeout(1000);
    ```

- Tests **must be independent**: no ordering, no shared mutable state. Setup goes in `test.beforeEach()` or a fixture.
- Never commit explore-only or debug specs (`console.log(await page.content())`, probes).
- After adding or modifying a spec, run `npx playwright test <file>` and **confirm zero failures** before reporting done.

## Procedure

1. Classify: functional (`tests/{area}/functional/`), API (`tests/{area}/api/`), E2E (`tests/{area}/e2e/`) or setup (`tests/{area}/*.setup.ts`). Run `ls tests/` to resolve `{area}`.
2. Open the nearest spec of the same type and copy its import, `describe` and `beforeEach` shape; a spec that must start signed out (login, anonymous forms) calls `resetStorageState()` in `beforeEach`; everything else starts signed in. Skeletons: `references/spec-patterns.md`.
3. Tag the test; when unsure which importance tag applies, read `references/tags.md`.
4. Split the body into `test.step()` blocks named GIVEN / WHEN / THEN. An API test with more than one call follows `api-testing`.
5. Take values from a factory or a static `.ts` file per `data-strategy`; a data-driven `for...of` loop sits inside `describe`, outside `test()`.
6. If the test mutates state, add the cleanup hook per `references/destructive-tests.md`; API setup or teardown shared by several specs goes through `api-testing`.
7. Run `npx playwright test <file>` and `npm run lint`; on red, load `debugging`.

## References

- `references/spec-patterns.md`: skeletons for a functional, data-driven, E2E and setup spec.
- `references/tags.md`: what each tag covers, how each suite runs, the three tagging mistakes.
- `references/destructive-tests.md`: the shared-state definition, the cleanup pattern, the destructive suite, suite-only failures.
