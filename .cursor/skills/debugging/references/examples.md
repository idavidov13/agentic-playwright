# Debugging — Worked Examples

Four end-to-end debug scenarios. Phase numbers refer to `debugging/SKILL.md`.

## Example 1: TimeoutError on an action

> `locator.click: Timeout 10000ms exceeded waiting for getByRole('button', { name: 'Submit' })`

Actions:

1. **Phase 1** — Action timeout = the click never connected. Source line points at `submitButton.click()`.
2. **Phase 2** — Action timeout → locator wrong / element disabled / not yet rendered.
3. **Phase 4 (UI Mode)** — replay; at the moment of click, the button has `aria-disabled="true"` because a required field is empty.
4. **Phase 5** — Fix the test setup to fill the required field first (or, if this case is supposed to surface the validation error, change the assertion to expect the validation error instead of the click to succeed).
5. **Phase 6** — Re-run the file 5x.

## Example 2: ZodError after a backend change

> `ZodError: at body.data.role: Invalid enum value. Expected 'admin' | 'user', received 'administrator'`

Actions:

1. **Phase 1** — `Schema.parse(body)` failed at `data.role`.
2. **Phase 2** — `ZodError` → contract drift.
3. **Phase 4 (UI Mode → Network tab)** — the response shows `role: 'administrator'`. The OpenAPI spec is the source of truth; if the spec still says `'admin' | 'user'`, this is a backend bug.
4. **Phase 5** — Per `api-testing` Phase 7: keep the test as the spec says, wrap with `test.skip` + `/* eslint-disable playwright/no-skipped-test */` + `// FIXME: <ticket-url>`. **Do not** loosen the schema. If the spec was updated to include `'administrator'`, update the enum and follow `refactor-values`.
5. **Phase 6** — Re-run.

## Example 3: Test passes alone, fails in suite

> `expect(appPage.username).toBeVisible() ... expected to be visible, received hidden` — passes via `--grep`, fails via `npm test`.

Actions:

1. **Phase 1 + 2** — assertion mismatch + intermittent → test independence violation.
2. **Phase 3** — reproduce: run the suite, then run the file alone — confirm the difference.
3. **Phase 4 (Trace Viewer on the suite-run failure)** — the trace shows the test starts already authenticated as a different user from a previous test that mutated state.
4. **Phase 5** — Add `resetStorageState` to `beforeEach`, factor any shared mutator into a `@destructive` test with proper cleanup (`test-standards` Phase 7). Use a factory for any per-test data.
5. **Phase 6** — Re-run `npm test` 5x.

## Example 4: CI fails, local is green

> Same spec file passes 5x locally; CI fails the very first run with `Timeout 30000ms exceeded waiting for navigation`.

Actions:

1. **Phase 7** — Download `playwright-report` and `test-results` artifacts from the CI run.
2. `npx playwright show-trace path/to/trace.zip` — the trace shows `page.goto(process.env.APP_URL)` returned `connection refused` for the first 25 seconds.
3. **Diagnosis** — CI's `auth.setup.ts` ran before the app container was ready. Local dev runs against an already-warm dev server.
4. **Fix** — Add a brief readiness probe in `auth.setup.ts` (or wait for the CI orchestration to expose a "ready" signal). **Do not** raise `navigationTimeout` — that masks the real timing.
5. **Phase 6** — Push the fix; verify the CI run is green.
