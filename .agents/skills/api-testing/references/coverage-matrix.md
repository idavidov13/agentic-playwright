# Coverage matrix

Every endpoint × method gets a test for every status code the contract documents, plus the baseline rows below, unless the human set a narrower scope (Scope, below). A documented code missing from this table still needs a test.

| Scenario                             | Status         | Assert                                                                            |
| ------------------------------------ | -------------- | --------------------------------------------------------------------------------- |
| Happy path (valid auth, valid body)  | 200/201        | schema parse; key fields match the sent data                                      |
| No `headers` (missing Authorization) | 401            | `status`; `UnauthorizedResponseSchema.parse(body)`                                |
| Wrong-role token                     | 403            | `status`; `ForbiddenResponseSchema.parse(body)`                                   |
| Empty body `{}` (POST/PUT/PATCH)     | 400/422        | `status`; error schema parse                                                      |
| Each required field omitted          | 400/422        | one test per field (`references/negative-testing.md`)                             |
| Each field with wrong types          | 400/422        | `for...of` per field (`references/negative-testing.md`)                           |
| Unknown resource id                  | 404            | `status`; `NotFoundResponseSchema.parse(body)`                                    |
| Invalid path-parameter formats       | 404            | data-driven loop (`references/negative-testing.md`)                               |
| Unsupported method                   | 405            | `status`                                                                          |
| Conflict, when documented            | 409            | the conflicting condition, or `test.skip` + `// FIXME` when it cannot be produced |
| Query parameters, when documented    | 400/422 or 200 | invalid type and out-of-range value per parameter                                 |
| No content (DELETE)                  | 204            | `status`; `expect(body).toBeNull()`                                               |

The Scenario column is the rule; the Status column is the demo API's convention. The expected status and error body come from the contract of the API under test. A baseline row the contract does not document: capture it live, flagged (`references/contract-sourcing.md`, Partially documented endpoint), and say so in the plan; never assume the table's code. Its test carries `// OBSERVED: <what the contract omits>, captured <YYYY-MM-DD>` on the line above it, so the next reader sees an observation, not a documented expectation. A live answer that looks wrong (a 5xx, a 2xx for invalid input) is a question for the human, not an expected value.

Error schemas live in `fixtures/api/schemas/util/errorResponseSchema.ts`: `UnauthorizedResponseSchema` (401, `{ error }`), `ForbiddenResponseSchema` (403, `{ message }`), `NotFoundResponseSchema` (404, `{ message }`), `UnprocessableEntityResponseSchema` (422, field name → messages). When the contract documents no body for a code, assert `expect(body).toBeNull()` instead of a parse. A new documented error shape is added there as a shared schema, never as a per-endpoint type.

## Scope

- The default is every row. Only the human narrows it, by naming the scenarios to automate or the rows to drop, in the request or at the plan gate. Never cut a row yourself. A vague hint ("keep it short") or a priority list with no cut-off does not say where to stop: propose every row and ask where the line is.
- Every row of the table can be cut, the baseline rows included: the Critical loops apply to the rows left in scope. A cut removes whole rows (a status code or a scenario), and a row that stays keeps its full loops. The request-body rows (empty body, field omitted, wrong types) are cut together or not at all, so an empty-body test never stands alone.
- A row is not applicable only when the endpoint lacks what it tests (no auth scheme, no path or query parameter, no body, not DELETE): say so in the plan, no line needed. A row that cannot be produced is not that: `FIXME` or a human cut.
- Each cut is a `// SCOPE` line in the `test.describe` it belongs to, naming the row and its source: the ticket URL or the name the human gave. Rows of one `test.describe` cut by the same source share one line. No source given: ask, never fill one in. It is a comment, not a test: an empty `test.skip` fails `npm run lint`.

    ```typescript
    test.describe('POST /users', () => {
        // SCOPE: 409 duplicate email; 403 wrong-role token: cut by <name or ticket-url>
        // ...the tests for the rows in scope
    });
    ```

- `// FIXME`, `// SCOPE` and `// OBSERVED` are different records. `FIXME` marks a product that disagrees with its contract: the test stays, skipped. `SCOPE` marks a row a human chose not to automate. `OBSERVED` marks a test whose expected status or body was captured live because the contract is silent. Never turn one into the other: a red or hard-to-produce test is a `FIXME` or a `debugging` case, never a `SCOPE` line.
- A later session reads the `// SCOPE` lines as the recorded scope and does not refill those rows unless the human asks. When the cut-off moves, the human's new list replaces the lines. `git grep -n '// SCOPE' -- tests/` lists every cut.

## Structure

- One `test.describe` per method + path; one spec file per resource under `tests/{area}/api/`.
- A resource several tests in the block share is created in `beforeAll` and deleted in `afterAll`; a POST block deletes what its happy-path test created in `afterAll`. Both hooks take the `apiRequest` fixture.
- Every test carries the `@api` tag (`test-standards`).

## Tokens

- `process.env.ACCESS_TOKEN` is the one token the scaffold mints: `tests/{area}/auth-api.setup.ts` calls `setUserAccessToken()` from `helpers/{area}/createStorageState.ts`, which saves it to `StorageStatePaths.API_ACCESS_TOKEN`; the `apiRequest` fixture file loads it once per worker (`helpers`). Pass it as `headers`; `authType` defaults to `Bearer`.
- The 401 row sends no `headers` at all.
- The 403 row needs a second, lower-privileged token. Extend the auth helper to mint it from a second credential pair declared in `env/.env.example`, or `test.skip` + `// FIXME` the row until the credentials exist. Never read an env var no helper populates.
