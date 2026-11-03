---
name: enums
description: Use when adding or extending an enum under enums/** (endpoint path, UI message, role, route, storage-state path) or deciding whether a repeated string is an enum at all. Not for URLs and credentials (see `config`), curated test inputs (see `data-strategy`) or changing an existing member (see `refactor-values`).
---

# Enums

## Critical

- A TypeScript `enum`, never an `as const` object: PascalCase name, SCREAMING_SNAKE_CASE members, the value exactly as the app uses it (case, punctuation, whitespace).

    ```typescript
    // CORRECT
    export enum ApiEndpoints {
        LOGIN = '/users/login',
    }
    // WRONG
    export const API_ENDPOINTS = { login: '/users/Login' } as const;
    ```

- Any app-defined string used in more than one place (endpoint path, UI message, role, route, storage-state path) lives in an enum and is imported; `ApiEndpoints` members are the only source of endpoint paths.
- App-specific enums in `enums/{area}/*.ts`, cross-app constants in `enums/util/*.ts`; extend an existing enum before creating a file, never a new top-level folder.
- Every enum declaration carries a JSDoc line naming what it groups.
- A UI message value is captured from the live app with `playwright-cli`, never guessed; app unreachable: add it with `// FIXME: unverified` and say so in the report.
- Changing or renaming an existing member goes through `refactor-values` first.

## Procedure

1. Classify the value; `ls enums/` resolves `{area}`. URLs and credentials go to `config`, curated test inputs to `data-strategy`, Playwright tuning to `playwright.config.ts`.

    | Value                                                   | Home                                                                                            |
    | ------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
    | Endpoint path, route, storage-state path                | `enums/{area}/*` (`ApiEndpoints`, `AppRoutes`, `StorageStatePaths` in `enums/app/app.ts`)       |
    | UI message (error, success, validation, label, heading) | `enums/{area}/*` (`Messages`), text captured live                                               |
    | Role or permission name                                 | `enums/util/*` (`Roles` in `enums/util/roles.ts`)                                               |
    | HTTP status code in an assertion                        | inline literal, `expect(status).toBe(200)`: the sanctioned carve-out from the magic-number rule |

2. Extend the enum that already groups the value; a new domain gets `enums/{area}/<domain>.ts` with its own JSDoc line.
3. UI text: open the page with `playwright-cli`, trigger the state, copy the rendered string into the value.
4. Add the member, then replace every hardcoded copy with the import: `grep -rn "<value>" tests pages fixtures helpers`.
5. Run `npx tsc --noEmit`, `npm run lint` and the consuming tests.

## References

- None. The live instances are `enums/app/app.ts` (`Messages`, `AppRoutes`, `ApiEndpoints`, `StorageStatePaths`) and `enums/util/roles.ts` (`Roles`).
