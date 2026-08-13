---
name: enums
description: TypeScript enum conventions for the Playwright scaffold — PascalCase enum names, SCREAMING_SNAKE_CASE members, location rules for app-specific (enums/{area}/) vs shared/utility (enums/util/) constants, and the rules for adding or extending enums. Use when adding a new API endpoint path, UI message, role, storage-state path, route, or any repeated string constant defined by the application; when deciding whether a new value belongs in enums/, config/, or test-data/static/; or when extending an existing enum. For URLs and credentials use the config skill, for curated test input data use the data-strategy skill, and for editing existing enum values use the refactor-values skill.
author: Ivan Davidov
---

# Enums

## Critical

- **Convention: TypeScript `enum`** — the scaffold uses the language construct `enum`, not `as const` object literals. Stay consistent.
- **Enum name:** PascalCase (e.g., `Messages`, `ApiEndpoints`, `Roles`, `StorageStatePaths`).
- **Enum member:** SCREAMING_SNAKE_CASE (e.g., `LOGIN_SUCCESS`, `CURRENT_USER`, `APP`).
- **Location:** app-defined strings go in `enums/{area}/*.ts`; cross-app constants go in `enums/util/*.ts`. Do not invent a new top-level folder.
- **JSDoc:** every enum declaration must have a JSDoc comment describing what the enum groups.
- **No hardcoded repeat strings.** Any string used in more than one place — endpoint paths, UI messages, roles, storage-state paths — must live in an enum and be imported.
- **Message values must match the real app.** For enums that mirror UI text (error messages, success messages, validation text), the string must be captured via `playwright-cli` from the live app, not guessed.
- **Edits to existing enum values go through `refactor-values`.** Renaming a key or changing a value cascades through tests, page objects, and schemas.

## File Locations

> **`{area}` is a placeholder.** Before creating or referencing any path below, run `ls enums/` to discover the real subdirectory names in this repo (e.g., `front-office`, `back-office`) and use those instead.

| Type                   | Directory       | Naming      | Scaffold examples                                                       |
| ---------------------- | --------------- | ----------- | ----------------------------------------------------------------------- |
| App-specific enums     | `enums/{area}/` | `[name].ts` | `Messages`, `ApiEndpoints`, `StorageStatePaths` (in `enums/app/app.ts`) |
| Shared / utility enums | `enums/util/`   | `[name].ts` | `Roles` (in `enums/util/roles.ts`)                                      |

## Instructions

### Phase 1: Decide if the value belongs in an enum

Use this decision table. Each row points to the canonical home — use it to prevent `enums/` from overlapping with `config/` or `test-data/static/`.

| Value kind                                                                 | Home                                                                     |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Endpoint path (`/api/users/login`), route (`/login`), storage-state path   | `enums/{area}/*`                                                         |
| UI message the app defines (error, success, validation, label, page title) | `enums/{area}/*` — verify text against the live app via `playwright-cli` |
| Role / permission name (`admin`, `user`, `guest`)                          | `enums/util/*` (shared across apps)                                      |
| HTTP status code, well-known cross-app constant                            | `enums/util/*`                                                           |
| URL of the app or a utility service, credentials, tokens                   | `config/` + env var — **not** an enum (see the `config` skill)           |
| Curated test inputs (invalid emails, weak passwords, out-of-range numbers) | `test-data/static/` — **not** an enum (see the `data-strategy` skill)    |
| Timeouts, retries, workers, project-wide Playwright tuning                 | `playwright.config.ts` — **not** an enum                                 |
| String literal used in exactly one place (single assertion, single setup)  | Inline in the consumer — do not promote to an enum                       |

If the value fits none of these rows, stop and ask. Do not invent a new location.

### Phase 2: Pick the home — new file or extend existing

Prefer **extending an existing enum file** within the same domain over creating a new file. The goal is to keep related constants together so consumers have one predictable import per domain.

- If a value fits into an existing enum (e.g., a new error message belongs in `Messages`), add it there.
- If the domain is genuinely new (e.g., a `checkout` domain that warrants its own file), create `enums/{area}/checkout.ts` and add one or more enums to it.
- Shared constants that apply across all apps go in `enums/util/*.ts`.

### Phase 3: Name the enum and its members

- **Enum name** — PascalCase, singular or plural per readability (`Messages`, `ApiEndpoints`, `Roles`, `StorageStatePaths`).
- **Enum member key** — SCREAMING_SNAKE_CASE.
- **Enum member value** — the actual string used by the app (exact case, exact punctuation).

**Correct:**

```typescript
export enum ApiEndpoints {
    LOGIN = '/api/users/login',
    CURRENT_USER = '/api/users/me',
}
```

**Incorrect:**

| Wrong                               | Problem                                              | Correct                            |
| ----------------------------------- | ---------------------------------------------------- | ---------------------------------- |
| `export enum API_ENDPOINTS { ... }` | Enum name is SCREAMING_SNAKE instead of PascalCase   | `export enum ApiEndpoints { ... }` |
| `export enum apiEndpoints { ... }`  | Enum name is camelCase instead of PascalCase         | `export enum ApiEndpoints { ... }` |
| `LOGIN_Success = '...'`             | Member mixes cases                                   | `LOGIN_SUCCESS = '...'`            |
| `loginSuccess = '...'`              | Member is camelCase instead of SCREAMING_SNAKE_CASE  | `LOGIN_SUCCESS = '...'`            |
| `LOGIN = '/api/users/Login'`        | Value case drifted from the real app path (`/login`) | `LOGIN = '/api/users/login'`       |

### Phase 4: Verify message values against the real app

When the enum mirrors UI text (error messages, success messages, validation text, button labels, page titles), the string value **must** come from observing the live application — not from assumptions, design specs, or guesses.

Workflow:

1. Read the `playwright-cli` skill (`.claude/skills/playwright-cli/SKILL.md`).
2. Run `playwright-cli` to trigger the relevant action in the app.
3. Capture the exact rendered text (case, punctuation, whitespace).
4. Encode it as the enum value.

If the app is unavailable, add the value with a `// FIXME: unverified` comment and flag it for confirmation once exploration is possible. Do not ship unverified message values.

### Phase 5: Add JSDoc and export

Every enum declaration gets a JSDoc comment describing the group:

```typescript
/** Common UI messages displayed to the user */
export enum Messages {
    LOGIN_SUCCESS = 'Successfully logged in',
    LOGIN_ERROR = 'Invalid email or password',
}
```

Re-use the pattern from `enums/app/app.ts`. The file itself may also carry a top-level JSDoc with an `@example` block (as the existing `enums/app/app.ts` does) when useful.

### Phase 6: Editing existing enum values

When you need to change an enum member's string value or rename a member key, the change cascades through tests, page objects, API schemas, and data-driven loops.

**Read the `refactor-values` skill** (`.claude/skills/refactor-values/SKILL.md`) **before** touching an existing enum. It owns the impact-analysis and cascading-update workflow.

## Examples

### Example 1: Add a new API endpoint path

User says: _"Add tests for `POST /api/products`."_

Actions:

1. **Phase 1** — Endpoint path → `enums/{area}/*` (app-specific).
2. **Phase 2** — `ApiEndpoints` already exists in `enums/app/app.ts` → extend it, don't create a new file.
3. **Phase 3** — Add `PRODUCTS = '/api/products'` (PascalCase enum, SCREAMING_SNAKE_CASE member, exact path case).
4. **Phase 5** — The existing JSDoc on `ApiEndpoints` already covers the group; no extra JSDoc needed for a single new member.
5. Consume in the API spec via `ApiEndpoints.PRODUCTS` (never hardcode `/api/products`).

### Example 2: Add a new UI message

User says: _"Assert the payment-failed message shows after a failed checkout."_

Actions:

1. **Phase 1** — App-defined UI text → `enums/{area}/*`.
2. **Phase 2** — `Messages` already exists in `enums/app/app.ts` → extend it.
3. **Phase 4** — Run `playwright-cli`, trigger the failed-payment flow, capture the exact rendered text.
4. **Phase 3** — Add `PAYMENT_FAILED = '<captured text>'`.
5. Consume in the test via `await expect(page.getByText(Messages.PAYMENT_FAILED)).toBeVisible();`.

### Example 3: Add a new shared role

User says: _"Support a moderator role in the test matrix."_

Actions:

1. **Phase 1** — Role → shared constant → `enums/util/*`.
2. **Phase 2** — `Roles` already exists in `enums/util/roles.ts` → extend it.
3. **Phase 3** — Add `MODERATOR = 'moderator'` (value is the exact wire string the app uses).
4. Consume wherever role checks or auth fixtures need it.

## Troubleshooting

**I'm about to hardcode `/api/users/login` in a test.**
Fix: Use `ApiEndpoints.LOGIN` from `enums/app/app.ts`. Any endpoint path used in more than one place must come from an enum.

**I'm about to hardcode an error message like `'Invalid credentials'` in an assertion.**
Fix: Use `Messages.*` from `enums/app/app.ts`. Verify the exact text via `playwright-cli` first (Phase 4); add a new member if needed.

**My enum value doesn't match the real UI text and a test fails at `expect(...).toBeVisible()`.**
Fix: Re-run `playwright-cli` to capture the actual rendered string (case, punctuation, whitespace). Update via the `refactor-values` workflow — do not fix it with a local find-and-replace that misses other consumers.

**I need to rename an enum member (e.g., `LOGIN_FAILED` → `LOGIN_REJECTED`).**
Fix: Stop. Read the `refactor-values` skill first. Use its impact-analysis workflow to find every consumer before renaming.

**My new value is an array (e.g., `[...invalid emails]`).**
Fix: That's not an enum — enums are named string constants, not collections of data. Put it in `test-data/static/{area}/*.ts` as an `as const` export (see the `data-strategy` skill).

**I want to put a URL like `https://staging.example.com` in an enum.**
Fix: URLs are environment-dependent and belong in `config/` + `process.env.*` (see the `config` skill). Enums are for source-controlled app-defined values.

**TypeScript complains about `enum` in my linter config.**
Cause: Some TS style guides discourage `enum` in favour of `as const` objects.
Fix: The scaffold's convention is TypeScript `enum`. If the linter flags it, configure the lint rule to allow `enum` at the repo level rather than migrating one file.

## See Also

- **`config`** skill — where URLs, credentials, and env-driven settings live (not enums).
- **`data-strategy`** skill — where curated arrays of test inputs live (not enums).
- **`playwright-cli`** skill — how to capture the real UI text before encoding it as a message enum value.
- **`refactor-values`** skill — impact analysis and cascading update workflow for enum renames and value changes.
- **`api-testing`** skill — consumer of `ApiEndpoints.*` for all endpoint references.
- **`debugging`** skill — when an assertion fails because `Messages.X` drifted from the live UI text, or when a test calls the wrong endpoint because `ApiEndpoints.X` is stale.
