---
name: helpers
description: Plain utility function conventions for the Playwright scaffold — app-specific helpers in helpers/{area}/ (authentication bootstrap, storage-state creation, data seeding) and generic utilities in helpers/util/ (date formatting, string manipulation, parsing). Use when adding a reusable function that does NOT need the Playwright fixture lifecycle, wiring authentication bootstrap in tests/{area}/auth.setup.ts, or deciding whether a reusable piece of code belongs in helpers/ or fixtures/. For Playwright fixtures with setup/use/teardown lifecycle use the fixtures skill; for the apiRequest-vs-helper-fixture-vs-factory decision when the helper makes API calls see the api-testing skill (Phase 8); for the env and enum sources of truth see the config and enums skills.
author: Ivan Davidov
---

# Helpers

## Critical

- **Helpers are plain functions.** No Playwright fixture lifecycle — no `use()`, no `base.extend`. If you need setup → `use(data)` → teardown, it's a **fixture**, not a helper (see the `fixtures` skill).
- **App-specific logic** lives in `helpers/{area}/` (e.g. `helpers/app/`). **Generic utilities** live in `helpers/util/`.
- **ALWAYS** add JSDoc with `@param` and `@returns` on every exported helper.
- **ALWAYS** specify explicit return types (`Promise<void>`, `string`, etc.). No implicit `any`.
- **NEVER** hardcode URLs, credentials, or tokens. Read env-driven values from `process.env.*` (see the `config` skill). Use `enums/{area}/*` for endpoint paths and storage-state paths.
- **ALWAYS** validate API responses inside helpers with the mandatory pattern `expect(SchemaName.parse(body)).toBeTruthy();` — identical to the `api-testing` Critical rule.
- **Function naming:** camelCase verbs (`createAppStorageState`, `setUserAccessToken`, `formatDate`, `parseCurrency`).
- **Do not promote a helper to a helper fixture** unless the same setup/teardown is copy-pasted across **3+** spec files and needs guaranteed lifecycle (see the `api-testing` skill, Phase 8 rule of thumb).
- **Mutating `process.env` from a helper is a narrow exception**, not a general pattern. It is acceptable only for auth-bootstrap helpers that publish a token (e.g. writing `process.env.ACCESS_TOKEN` inside a login helper). Do not copy the env-mutation pattern into other helpers — return values through the function signature instead.

## File Locations

> **`{area}` is a placeholder.** Before creating or referencing any path below, run `ls helpers/` to discover the real subdirectory names in this repo (e.g., `front-office`, `back-office`) and use those instead.

| Type            | Directory         | Purpose                                                                | Scaffold example                    |
| --------------- | ----------------- | ---------------------------------------------------------------------- | ----------------------------------- |
| App helpers     | `helpers/{area}/` | App-specific helper functions (auth bootstrap, storage state, seeding) | `helpers/app/createStorageState.ts` |
| Utility helpers | `helpers/util/`   | Generic utility functions reusable across apps/projects                | `helpers/util/util.ts`              |

## Instructions

### Phase 1: Classify what you're adding

Use this table. The correct criterion is **"does this need the Playwright fixture lifecycle?"** — not _"is this used in setup or in tests?"_. A plain utility like `formatDate` is a helper even though it's called from inside tests.

| Symptom                                                                                          | Home                                                                                        |
| ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| Pure function — no setup/teardown lifecycle needed                                               | **Helper** in `helpers/{area}/` or `helpers/util/`                                          |
| Needs `page` / `request` context via DI, or owns setup → `use(data)` → teardown around each test | **Fixture** (see the `fixtures` skill; for lifecycle API helpers see `api-testing` Phase 8) |
| Encapsulates locators and user interactions on a specific page                                   | **Page object** (see the `page-objects` skill)                                              |
| One-off API call inside a single test                                                            | Call `apiRequest` **directly** in the test — neither helper nor fixture                     |
| Reusable happy-path data generation                                                              | **Factory** under `test-data/factories/{area}/` (see the `data-strategy` skill)             |

If the need fits none of these rows, stop and ask. Do not invent a new location.

### Phase 2: Pick the home — app-specific or utility

- **`helpers/{area}/`** — logic that only makes sense for the app under test: authentication flows, storage state creation, data seeding, app-specific request composition.
- **`helpers/util/`** — logic that's reusable across apps or projects: date formatting, string manipulation, retry logic, parsing utilities.

Prefer **extending an existing file** (`createStorageState.ts`, `util.ts`) over creating a new one when the function belongs to the same domain. Create a new file only when the domain is genuinely new.

### Phase 3: Define the function signature, types, and JSDoc

Every exported helper must declare:

- An **explicit return type** (`Promise<void>`, `string`, `UserResponse`, etc.). No implicit `any`.
- **Named parameters** with explicit types.
- A **JSDoc** block with a description, `@param` for every argument, `@returns`, and — when useful — an `@example` block.

Pattern:

```typescript
/**
 * Creates and saves the browser storage state after successful login.
 * @returns {Promise<void>} Resolves when storage state is saved.
 */
export async function createAppStorageState(): Promise<void> {
    // implementation
}
```

### Phase 4: Read env-driven values from `process.env.*`

Helpers **never** hardcode URLs, credentials, or tokens. Read from `process.env.*` and use enums for endpoint paths / storage-state paths:

```typescript
import { ApiEndpoints, StorageStatePaths } from '../../enums/app/app';

// CORRECT
baseUrl: process.env.API_URL,
url: ApiEndpoints.LOGIN,
body: { email: process.env.APP_EMAIL, password: process.env.APP_PASSWORD },
await context.storageState({ path: StorageStatePaths.APP });

// FORBIDDEN
baseUrl: 'https://api.example.com',
url: '/api/users/login',
```

See the `config` skill for sources of truth and the `enums` skill for paths.

### Phase 5: If the helper makes API calls, validate with Zod

The mandatory API response-validation pattern from `api-testing` applies equally inside helpers:

```typescript
const { status, body } = await apiRequest<UserResponse>({
    method: 'POST',
    url: ApiEndpoints.LOGIN,
    baseUrl: process.env.API_URL,
    body: { email: process.env.APP_EMAIL, password: process.env.APP_PASSWORD },
});

expect(status).toBe(200);
expect(UserResponseSchema.parse(body)).toBeTruthy();
```

Rules:

- The generic `<UserResponse>` gives compile-time safety on `body`.
- `expect(SchemaName.parse(body)).toBeTruthy();` is the exact assertion — not `schema.parse(body)` alone.
- If the response can legitimately be `null` (e.g., a 204 DELETE), assert `expect(body).toBeNull()` instead.

### Phase 6: Consume the helper

Call the helper from the right context — helpers have no lifecycle of their own, so **where** you call them matters:

- **Auth bootstrap (`tests/{area}/auth.setup.ts`)** — app-login helpers run once before the main test suite to produce storage state and/or tokens. The scaffold ships a demo implementation in `helpers/app/createStorageState.ts`; adapt or replace it to match your app's auth flow.
- **Inside a test / `beforeEach` / `afterEach`** — utility helpers freely, API helpers when they do self-contained work.
- **Inside a fixture** — a fixture can call a helper as part of its setup/teardown. The fixture owns the lifecycle; the helper stays stateless.

Auth-bootstrap helpers that publish a token via `process.env.*` (e.g. the demo `setUserAccessToken` in the scaffold) are the one place env mutation is acceptable. Every other helper must return its results through the function signature.

## Examples

### Example 1: Add a utility helper

User says: _"Add a helper that parses a currency string like `$1,234.56` into a number so tests can assert on cart totals."_

Actions:

1. **Phase 1** — Pure function, no lifecycle → helper.
2. **Phase 2** — Generic, reusable across apps → `helpers/util/util.ts` (extend the existing file).
3. **Phase 3** — Signature: `export function parseCurrency(value: string): number`, with JSDoc + `@param` + `@returns`.
4. **Phase 6** — Consume inside tests: `expect(parseCurrency(await cart.totalText())).toBe(1234.56);`.

### Example 2: Add an app-specific seeding helper

User says: _"Wrap the factory + API create call so setup scripts can seed a product."_

Actions:

1. **Phase 1** — Plain function (takes `apiRequest` as a parameter; does not own lifecycle) → helper. If it needed guaranteed per-test teardown, it would be a fixture instead.
2. **Phase 2** — App-specific → `helpers/{area}/` (e.g. `helpers/app/seedProduct.ts`).
3. **Phase 3** — Signature: `export async function seedProduct(apiRequest: ApiRequestFn, overrides?: Partial<Product>): Promise<Product>`.
4. **Phase 4** — Read base URL / token from `process.env.*`, endpoint from `ApiEndpoints.PRODUCTS`.
5. **Phase 5** — Validate the response: `expect(status).toBe(201);` + `expect(ProductSchema.parse(body)).toBeTruthy();`.
6. **Phase 6** — Call from `tests/{area}/auth.setup.ts` or inside a fixture's setup block.

### Example 3: Counterexample — this is a fixture, not a helper

User says: _"I want to write a helper that creates a test user before each test and deletes it after — same API I wrote for `seedProduct`."_

Actions:

1. **Phase 1** — "Creates before, deletes after" = Playwright lifecycle → **fixture**, not a helper.
2. Stop. Route to the `fixtures` skill + the `api-testing` skill (Phase 8) and promote only if the setup/teardown is reused across **3+** spec files.
3. If it's used in only 1–2 files, keep it inline in `beforeEach` / `afterEach` using `apiRequest` directly.

## Troubleshooting

**My helper returns `undefined` for `process.env.*` values.**
Cause: Missing env variable in the active `env/.env.${ENVIRONMENT}` file.
Fix: Confirm the key exists there; update `env/.env.example` if you added a new variable. See the `config` skill.

**I want the helper to set up a resource and tear it down around each test.**
Fix: That's a fixture, not a helper. Route to the `fixtures` skill; if the setup/teardown is API-driven see the `api-testing` skill (Phase 8).

**`process.env.ACCESS_TOKEN` (or whichever token env var your auth helper writes) is `undefined` in API tests.**
Cause: The auth-setup test didn't run, or your login helper failed silently before writing the env var.
Fix: Confirm Playwright's project dependencies are wired so `tests/{area}/auth.setup.ts` runs before the main suite. Re-run the setup and watch for schema-parse failures inside the auth helper (a schema mismatch means the login response shape changed).

**My API helper calls `schema.parse(body)` without wrapping in `expect(...).toBeTruthy()`.**
Cause: Old pattern.
Fix: Replace with `expect(SchemaName.parse(body)).toBeTruthy();` — identical to the `api-testing` Critical rule.

**I want to mutate `process.env` inside a new helper for convenience.**
Fix: Don't. The `setUserAccessToken` env mutation is a sanctioned auth-bootstrap exception. For any other case, pass values through return types or factory overrides — env mutation hides state and breaks parallel isolation.

**I'm about to promote a one-off helper to a helper fixture because "it feels reusable".**
Fix: Promote only when the same setup/teardown is copy-pasted across **3+** spec files with a lifecycle need. Otherwise keep it as a helper or an inline `apiRequest` call (see the `api-testing` skill, Phase 8 rule of thumb).

**TypeScript complains that my helper has an implicit `any` return type.**
Fix: Add an explicit return type (`Promise<void>`, `Promise<UserResponse>`, `string`, etc.) — Critical rule.

## See Also

- **`fixtures`** skill — Playwright fixtures with `use()` lifecycle (setup / yield / teardown); the sibling category to helpers.
- **`api-testing`** skill — mandatory `expect(Schema.parse(body)).toBeTruthy();` pattern and the Phase 8 rule of thumb for promoting to a helper fixture.
- **`config`** skill — env variable conventions (`process.env.*`), where `APP_URL` / `API_URL` / `APP_EMAIL` / `APP_PASSWORD` live.
- **`enums`** skill — `ApiEndpoints.*` for endpoint paths and `StorageStatePaths.*` for storage-state file paths.
- **`data-strategy`** skill — Faker + Zod factories used inside seeding helpers; three-tier rule for static invalid data.
- **`debugging`** skill — `process.env.ACCESS_TOKEN` undefined, auth-bootstrap failures, and other helper-driven test failures.
