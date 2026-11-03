# Coverage matrix

Every endpoint × method gets a test for every status code the contract documents, plus the baseline rows below. A documented code missing from this table still needs a test.

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

Error schemas live in `fixtures/api/schemas/util/errorResponseSchema.ts`: `UnauthorizedResponseSchema` (401, `{ error }`), `ForbiddenResponseSchema` (403, `{ message }`), `NotFoundResponseSchema` (404, `{ message }`), `UnprocessableEntityResponseSchema` (422, field name → messages). When the contract documents no body for a code, assert `expect(body).toBeNull()` instead of a parse. A new documented error shape is added there as a shared schema, never as a per-endpoint type.

## Structure

- One `test.describe` per method + path; one spec file per resource under `tests/{area}/api/`.
- A resource several tests in the block share is created in `beforeAll` and deleted in `afterAll`; a POST block deletes what its happy-path test created in `afterAll`. Both hooks take the `apiRequest` fixture.
- Every test carries the `@api` tag (`test-standards`).

## Tokens

- `process.env.ACCESS_TOKEN` is the one token the scaffold mints: `tests/{area}/auth-api.setup.ts` calls `setUserAccessToken()` from `helpers/{area}/createStorageState.ts`, which saves it to `StorageStatePaths.API_ACCESS_TOKEN`; the `apiRequest` fixture file loads it once per worker (`helpers`). Pass it as `headers`; `authType` defaults to `Bearer`.
- The 401 row sends no `headers` at all.
- The 403 row needs a second, lower-privileged token. Extend the auth helper to mint it from a second credential pair declared in `env/.env.example`, or `test.skip` + `// FIXME` the row until the credentials exist. Never read an env var no helper populates.
