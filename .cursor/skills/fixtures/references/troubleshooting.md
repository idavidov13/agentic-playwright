# Fixtures — Troubleshooting

## TypeScript says `appPage` (or any fixture) doesn't exist on the test context

**Cause:** The spec file imported `test` from `@playwright/test` instead of `fixtures/pom/test-options.ts`.
**Fix:** Replace the import with `import { test, expect } from '../../../fixtures/pom/test-options';`.

## I promoted a one-off API call to a fixture and now every test loads it

**Cause:** Fixtures run for every test that injects them — if you add `featureFlag` to `HelperFixtures`, any test destructuring `{ featureFlag }` pays the setup/teardown cost.
**Fix:** Remove the fixture and call `apiRequest` directly in the one test (or a focused `beforeEach`). Promote back to a helper fixture only when the same setup is copy-pasted across 3+ spec files (see the `api-testing` skill, Phase 8 rule of thumb).

## My helper fixture's teardown code never runs

**Cause:** The teardown is written before `await use(...)`, or `await use(...)` is missing.
**Fix:** Structure the fixture as `setup → await use(data) → teardown`. Every code path after `await use(...)` is the teardown and runs automatically after the test (even on failure).

## I added a new fixture category file but nothing is injected into tests

**Cause:** You forgot to merge the new category into `fixtures/pom/test-options.ts`.
**Fix:** Append it to the `mergeTests(...)` call. Page objects and lifecycle helpers are already merged — only **new categories** need this step.

## I wrote a reusable function and don't know whether to put it in `fixtures/` or `helpers/`

**Answer:** If the function needs the Playwright fixture lifecycle (setup → `use()` → teardown), it's a **fixture** (`fixtures/helper/helper-fixture.ts`). If it's a plain function you call from a test or a fixture without needing lifecycle hooks, it's a **helper** (`helpers/`, see the `helpers` skill). A login-+-capture-storage-state utility is a helper. A per-test resource create-+-delete pair is a fixture.

## TypeScript says my new fixture exists on `base.extend` but not on the test context

**Cause:** You created the fixture implementation but didn't add the property to the `FrameworkFixtures` or `HelperFixtures` type.
**Fix:** Add it to the type literal, then the test context picks it up automatically.

## I want to `new AppPage(page)` inside a `beforeEach` because the fixture approach feels heavier

**Fix:** Don't. Use the fixture. Manual instantiation breaks the DI contract, makes the test depend on the page object's constructor signature, and sidesteps any setup that the fixture performs. If the fixture feels heavy, that's a fixture-design smell to fix at the fixture, not bypass.
