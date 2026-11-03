---
name: api-testing
description: Use when writing or updating an API spec under tests/**/api/**, planning coverage for an endpoint, building a response schema from the API contract, or deciding whether API setup/teardown becomes a helper fixture. Not for Zod syntax and type inference (see `type-safety`) or fixture mechanics (see `fixtures`).
---

# API Testing

## Critical

- Never hardcode API URLs, access tokens, emails, passwords or endpoint paths: only `process.env.API_URL`, `process.env.ACCESS_TOKEN`, `process.env.APP_EMAIL` / `APP_PASSWORD` and `ApiEndpoints` from `enums/{area}/*`.
- Schemas and tests come from the documented contract (OpenAPI / Swagger), never from a request made first; no document found: stop and ask.
- Assert every response body with `expect(SchemaName.parse(body)).toBeTruthy();`, not a generic or a bare parse; in fixture code, with no test to assert in, `const x = SchemaName.parse(body);`. Never `as`-cast.

    ```typescript
    // CORRECT
    expect(UserResponseSchema.parse(body)).toBeTruthy();
    // WRONG
    const user = body as UserResponse;
    ```

- A test with more than one API call wraps each call in its own `test.step()`, assertions inside the step.
- Never change an expected status, loosen a schema or drop a test: keep it as the contract says, wrapped in `test.skip` with `// FIXME: <ticket-url>`. 422 where the spec says 400 is still a mismatch; only a human confirming the spec is stale changes the expectation.

    ```typescript
    // CORRECT
    // FIXME: <ticket-url> spec 422, API 500
    test.skip('returns 422 for bad price', { tag: '@api' }, async () => {});
    // WRONG
    expect(status).toBe(500);
    ```

- Every request-body endpoint gets an empty-body test, a per-field omission loop and a per-field invalid-type `for...of` loop over the `INVALID_*` arrays; never empty-body-only.
- Always fuzz path parameters with the invalid-format loop, documented or not.
- Call `apiRequest` directly in tests and hooks; promote to a helper fixture in `fixtures/helper/helper-fixture.ts` only when the same setup/teardown is copy-pasted into 3+ test files (canonical threshold, other skills point here).

## Procedure

1. Locate the contract: a spec file in the repo, the API host's documentation route, or a document from the human. Nothing found: ask. Partial or absent: `references/contract-sourcing.md`.
2. Write the response schema in `fixtures/api/schemas/{area}/` per `type-safety` (`ls fixtures/api/schemas/` resolves `{area}`); error bodies use `fixtures/api/schemas/util/errorResponseSchema.ts`.
3. Add a new path to `ApiEndpoints` per `enums`.
4. Write the happy path: `apiRequest<SchemaType>({ method, url: ApiEndpoints.X, baseUrl: process.env.API_URL, headers: process.env.ACCESS_TOKEN, body })` in a `test.describe` per method + path, tag `@api`, payload from a factory per `data-strategy`.
5. List every status code the contract documents plus the baseline rows in `references/coverage-matrix.md`; present the plan before writing those tests.
6. Add the negative loops from `references/negative-testing.md`; a test with several calls follows `references/multi-call-steps.md`.
7. Setup or teardown past the threshold goes to `references/helper-fixtures.md`; below it, `beforeAll`/`afterAll` in the spec with `apiRequest`.
8. Run `npx playwright test <file>` and `npm run lint`. A response that disagrees with the contract: `test.skip` + `// FIXME`; red for another reason: `debugging`.

## References

- `references/contract-sourcing.md`: open when the contract is partial, missing or unversioned.
- `references/coverage-matrix.md`: the status-code rows every endpoint × method needs, the describe structure, the token conventions.
- `references/negative-testing.md`: the per-field invalid-type, omission, path-parameter and query-parameter loops.
- `references/multi-call-steps.md`: the create → read `test.step()` pattern with cleanup.
- `references/helper-fixtures.md`: the setup → `use()` → teardown pattern for promoted API setup.
