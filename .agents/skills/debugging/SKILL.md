---
name: debugging
description: Use when a Playwright test fails, flakes or times out, when `Schema.parse(body)` throws a ZodError, or when CI is red and local is green. Not for the contract-mismatch protocol itself (see `api-testing`) or changing a drifted enum value (see `refactor-values`).
---

# Debugging

## Critical

- **Read the failure message before touching code.** It names the test, the failed call with expected versus received, and the source line.
- **Never suppress a failure.** No `test.skip` without `// FIXME: <ticket-url>`, no loosened assertion or schema, no timeout bump, no `try/catch` around `expect`. A response that disagrees with the documented contract follows the `api-testing` protocol.
- **Never add `page.waitForTimeout(...)` to fix timing.** Use a web-first assertion or `page.waitForResponse(...)` in the page-object action.
- **Never ship a fix you could not reproduce.** Reproduce locally or replay the CI artifacts first.
- **Traces exist only after a retry.** `trace: 'on-first-retry'` with `retries: 0` locally means no trace by default; run with `--trace on` or use UI Mode.
- **A flake fix needs 5 consecutive green runs** of the affected file with `--workers=1 --retries=0`.
- **Never commit `test.only`**; narrow with a file path or `--grep` instead. After every fix, `npm run lint` and the affected file must be green.

## Procedure

1. Read the failure output in full.
2. Classify with the table; the next step names the tool and the owning skill.

    | Symptom                                                       | Likely cause                                                    | Next step                                                                                                  |
    | ------------------------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
    | `locator.click ... Timeout`, or "not attached to the DOM"     | wrong locator, disabled element, action raced a navigation      | trace or UI Mode at the failing action; fix the getter (`selectors`) or the action's wait (`page-objects`) |
    | `expect(locator).toBeVisible() ... Timeout`                   | element not visible, wrong locator, race with navigation        | UI Mode snapshot before the assertion; fix the locator or the preceding action                             |
    | `page.goto ... Timeout`                                       | wrong `APP_URL`, env file not loaded, app down                  | `curl` the URL, `ls env/`; `config`                                                                        |
    | `strict mode violation ... resolved to N elements`            | selector too loose                                              | `selectors`: `{ exact: true }` or scope to a parent                                                        |
    | `Expected: "X" / Received: "Y"`                               | page state, data or an enum value drifted                       | compare on the live app; a `Messages.*` drift → `refactor-values`                                          |
    | `ZodError` from `Schema.parse(body)`                          | response disagrees with the schema                              | documented contract → bug, `api-testing` protocol; undocumented → update the schema (`type-safety`)        |
    | `ECONNREFUSED`, `ENOTFOUND`, 5xx, or 401 on a protected route | wrong `API_URL`, API down, token not loaded                     | `config`; `helpers` (auth bootstrap)                                                                       |
    | `ENOENT ... appStorageState.json`                             | the `setup-ui` project did not run or failed                    | `npx playwright test --project setup-ui`; check `env/.env.dev`                                             |
    | `appPage is undefined`, `cannot read property of undefined`   | fixture not registered, `test` imported from `@playwright/test` | `fixtures`; `npm run lint`                                                                                 |
    | green alone, red in the suite                                 | shared state between tests, missing `resetStorageState`         | `test-standards` (independence)                                                                            |

3. Reproduce: `npx playwright test <file> --workers=1 --retries=0`, `--grep "<title>"` to narrow further. Green locally, red in CI → `references/ci-replay.md`.
4. Investigate with one tool from `references/tools.md`.
5. Fix at the root cause in the file the table names, not by patching the spec around it.
6. Re-run the file (5× for a flake), then `npm run lint`; remove any `test.only` and instrumentation before committing.

## References

- `references/tools.md`: step 4, which tool for which failure and the commands.
- `references/ci-replay.md`: step 3, when CI is red and local is green.
