# Debugging — Troubleshooting

## There's no trace file even though the test failed

**Cause:** `playwright.config.ts` sets `trace: 'on-first-retry'`. Locally `retries: 0`, so no retry runs, so no trace.
**Fix:** Re-run with `--trace on` (or `--trace retain-on-failure`), or use UI Mode (`npm run test:ui`) which always traces.

## `npm run report` opens an empty / old report

**Cause:** Either no run has produced one yet, or `playwright-report/` is stale.
**Fix:** Run the failing test once first to refresh the report, then `npm run report`.

## `test.only(...)` works locally but the CI build is failing with `forbidOnly`

**Cause:** You committed `test.only(...)`. `playwright.config.ts` has `forbidOnly: !!process.env.CI`.
**Fix:** Remove `test.only(...)` and re-push. Use `--grep` to narrow in CI workflows.

## UI Mode is slow / consumes lots of memory

**Fix:** Close the browser after each session; UI Mode keeps a hot context. If you only need post-mortem, prefer Trace Viewer on the captured trace instead.

## I bumped a timeout to make the assertion pass

**Cause:** You masked a real bug.
**Fix:** Revert the timeout. Re-run with UI Mode or Trace and find what the page is actually waiting on. The right fix is almost always: a missing `waitForResponse` in the page-object action, a wrong locator, or a missing precondition.

## I added `try/catch` around `expect(...)` so the test "passes"

**Cause:** Suppressing an assertion is a coverage drop.
**Fix:** Remove the catch. If the API is the bug, follow `api-testing` Phase 7. If the test logic is wrong, fix the test.

## I think the failure is intermittent (flaky)

**Cause:** Almost always one of: shared state between tests, race between an action and navigation, a non-deterministic locator, or a hardcoded string used in two places that drifted.
**Fix:** Reproduce by running the file 10x with `--workers=1 --retries=0`. If it never reproduces alone but does in the suite, it's a **test independence** issue (`test-standards` Phase 9). If it reproduces alone, it's a timing / locator issue — UI Mode or Trace Viewer.

## `npm test` reports a destructive test ran and broke things

**Cause:** A test was promoted to `@destructive` but the cleanup `afterEach` is missing or wrong.
**Fix:** `test-standards` Phase 7 — every `@destructive` test must have idempotent cleanup. Until cleanup is in, the test stays out of the suite.

## My fix works on chromium but I want to know if it'll break other browsers

**Cause:** Default project is `chromium`; firefox / webkit are commented out in `playwright.config.ts`.
**Fix:** Uncomment the other project blocks for the duration of debugging, run with `--project=firefox` or `--project=webkit`, then re-comment when done. Cross-browser tuning is out of scope of this skill — coordinate with the team before enabling more projects in CI.
