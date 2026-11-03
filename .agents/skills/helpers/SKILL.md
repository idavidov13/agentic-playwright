---
name: helpers
description: Use when adding a reusable plain function under helpers/**, wiring the auth bootstrap in tests/{area}/*.setup.ts, or deciding whether reusable code is a helper or a fixture. Not for fixtures with a setup/use/teardown lifecycle (see `fixtures`) or the helper-fixture promotion threshold (see `api-testing`).
---

# Helpers

## Critical

- A helper is a plain exported function with no Playwright lifecycle: no `base.extend`, no `use()`. Code that must run before and after each test is a fixture (`fixtures`).
- App-specific helpers live in `helpers/{area}/`, generic utilities in `helpers/util/`; extend the existing file of the same domain before creating one, never a new top-level folder.
- Every exported helper has an explicit return type, typed parameters and a JSDoc block with `@param` and `@returns`; names are camelCase verbs (`createAppStorageState`, `formatDate`).

    ```typescript
    // CORRECT
    export function formatDate(value: number | string): string {
        return new Date(value).toLocaleDateString('en-US');
    }
    // WRONG
    export const formatDate = (value) => new Date(value).toLocaleDateString();
    ```

- URLs, credentials and tokens come from `process.env.*` (`config`); endpoint and storage-state paths from `enums/{area}/*` (`enums`); never a literal.
- A helper that calls the API takes `apiRequest` as a parameter and asserts the body with `expect(SchemaName.parse(body)).toBeTruthy();` (`api-testing`).
- `process.env` is written only by the auth bootstrap in `helpers/{area}/createStorageState.ts`; every other helper returns its result through its signature.

## Procedure

1. Classify: no lifecycle → helper; setup → `use()` → teardown → `fixtures`; locators and interactions on a page → `page-objects`; one API call in one test → `apiRequest` inline; happy-path data → `data-strategy`. `ls helpers/` resolves `{area}`.
2. Pick the file: `helpers/{area}/<domain>.ts` for app logic, `helpers/util/util.ts` for a generic utility.
3. Write the function with its signature and JSDoc, sources per Critical; auth work follows `references/auth-bootstrap.md`.
4. Call it from the setup spec, a test, a hook or a fixture; run `npx tsc --noEmit`, `npm run lint` and the consuming tests.

## References

- `references/auth-bootstrap.md`: open when touching `tests/{area}/*.setup.ts` or the token and storage-state chain, or when `process.env.ACCESS_TOKEN` is `undefined` in a test.
