---
applyTo: 'fixtures/api/**/*.ts,tests/**/api/**/*.ts'
---

# API Testing

## Critical

These rules are non-negotiable. Violating any of them breaks the scaffold's contract.

- **NEVER** hardcode API URLs, access tokens, emails, passwords, or endpoint paths. The only allowed sources of truth are `process.env.*` (for URLs and credentials) and the `enums/{area}/*` enums (for endpoint paths, e.g. `ApiEndpoints.LOGIN`).
- **ALWAYS** validate API response bodies with Zod using the exact assertion pattern `expect(SchemaName.parse(body)).toBeTruthy();`. Type generics alone are not enough, and `schema.parse(body)` without the `expect(...).toBeTruthy()` wrapper is not enough.
- **ALWAYS** wrap each API call in `test.step()` when a test contains more than one API call.
- **NEVER** silently drop a test because the API misbehaves. Write the test as the spec says, wrap it in `test.skip`, and add a `// FIXME: <ticket-url>` comment.
- **NEVER** stop at `{}` empty-body validation. Every request-body endpoint requires per-field omission and per-field invalid-type tests.
- **ALWAYS** fuzz path parameters with the invalid-format data-driven loop — regardless of whether OpenAPI mentions it.
- **ALWAYS** use the `apiRequest` fixture directly in tests. Only promote to a helper fixture when the same setup/teardown is reused across 3+ test files.

## Instructions

### Phase 1: Source the contract (documentation first, exploration only as fallback)

The API contract — not observed behavior — is the source of truth for schemas and tests.

1. **If OpenAPI / Swagger / equivalent documentation exists (the normal case):**
    - Build schemas and tests **strictly from the documented contract**: field names, types, required vs optional, nullability, status codes, error shapes.
    - **Do NOT** curl the endpoint first to "see what it returns" and then write schemas that match reality.
    - If, during test execution, the actual response disagrees with the documentation (missing field, wrong type, wrong status code, extra field), that is a **bug to report**, not a reason to loosen the schema. Handle it via Phase 7 (`test.skip` + `// FIXME: <ticket-url>`).

2. **Only if no documentation is provided** (legacy endpoint, undocumented service, etc.):
    - Make a real request to discover actual response structure, field names, data types, optional vs required fields, nested objects/arrays, and error response formats.
    - Capture the findings and treat them as the working contract for this skill's remaining phases.
    - Flag the missing documentation back to the team — running tests against "whatever the API currently does" is a stopgap, not a target state.

### Phase 2: Define the Zod schema and TypeScript type

Schemas live under `fixtures/api/schemas/`.

> **`{area}` is a placeholder.** Run `ls fixtures/api/schemas/` to discover the real subdirectory names in this repo (e.g., `front-office`, `back-office`) and use those instead.

```
fixtures/api/schemas/
├── {area}/         ← App-specific response/request schemas
│   └── userSchema.ts
└── util/           ← Shared error response schemas
    └── errorResponseSchema.ts
```

Build the schema directly from the OpenAPI / Swagger contract — including the response envelope (`success / message / data / errors` or whatever the spec describes). Spell every field out per endpoint; do not invent a factory helper. If the same envelope repeats across many endpoints in one domain, extract a per-domain `_envelope.ts` (`z.strictObject`) and compose via `.extend(...)` — only after the repetition is real:

```typescript
// fixtures/api/schemas/{area}/productSchema.ts
import { z } from 'zod/v4';
import type { output as zOutput } from 'zod/v4';

export const ProductSchema = z.strictObject({
    id: z.uuid(),
    name: z.string().min(1),
    price: z.number().positive(),
    category: z.enum(['electronics', 'clothing', 'food']),
    inStock: z.boolean(),
});

// Response envelope is spelled out per the OpenAPI contract -- 1:1 mirror.
export const CreateProductResponseSchema = z.strictObject({
    success: z.boolean(),
    message: z.string(),
    data: ProductSchema,
    errors: z.unknown().nullable(),
});

export type Product = zOutput<typeof ProductSchema>;
export type CreateProductResponse = zOutput<typeof CreateProductResponseSchema>;
```

**Error response schemas** already exist in `fixtures/api/schemas/util/errorResponseSchema.ts`:

- `BadRequestResponseSchema` (400)
- `UnauthorizedResponseSchema` (401)
- `ForbiddenResponseSchema` (403)
- `NotFoundResponseSchema` (404)

```typescript
import {
    UnauthorizedResponse,
    UnauthorizedResponseSchema,
} from '../../../fixtures/api/schemas/util/errorResponseSchema';

const { status, body } = await apiRequest<UnauthorizedResponse>({
    method: 'POST',
    url: '/api/login',
    baseUrl: process.env.API_URL,
    body: { email: 'bad@email.com', password: 'wrong' },
});

expect(status).toBe(401);
expect(UnauthorizedResponseSchema.parse(body)).toBeTruthy();
```

For **401** and **403** responses that return a null body, assert `expect(body).toBeNull()` directly — no schema needed.

### Phase 3: Write the test using the `apiRequest` fixture

Use the `apiRequest` fixture for all API calls in tests. It provides type-safe requests with automatic response parsing via Playwright's dependency injection:

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';
import {
    UserResponse,
    UserResponseSchema,
} from '../../../fixtures/api/schemas/app/userSchema';

test('should return user data', { tag: '@api' }, async ({ apiRequest }) => {
    const { status, body } = await apiRequest<UserResponse>({
        method: 'GET',
        url: '/api/users/me',
        baseUrl: process.env.API_URL,
        headers: process.env.ACCESS_TOKEN,
    });

    expect(status).toBe(200);
    expect(UserResponseSchema.parse(body)).toBeTruthy();
});
```

Use the `apiRequest` fixture **directly** for all API work in tests — assertions, setup calls in `beforeEach`, teardown calls in `afterEach`, and one-off requests. Do **not** create a separate helper fixture for every endpoint.

**Request parameters:**

| Option     | Type                                              | Required | Description                         |
| ---------- | ------------------------------------------------- | -------- | ----------------------------------- |
| `method`   | `'GET' \| 'POST' \| 'PUT' \| 'DELETE' \| 'PATCH'` | Yes      | HTTP method                         |
| `url`      | `string`                                          | Yes      | Endpoint path                       |
| `baseUrl`  | `string`                                          | No       | Base URL to prepend                 |
| `body`     | `Record<string, unknown>`                         | No       | Request payload                     |
| `headers`  | `string`                                          | No       | Auth token for Authorization header |
| `authType` | `'Bearer' \| 'Token' \| 'Basic'`                  | No       | Auth scheme (default: `'Bearer'`)   |

**Response validation** — combine compile-time and runtime safety:

```typescript
const { status, body } = await apiRequest<UserResponse>({ ... });

expect(UserResponseSchema.parse(body)).toBeTruthy();
```

The generic `<UserResponse>` gives you compile-time type safety on `body`, while `UserResponseSchema.parse()` gives you runtime validation. Always use both.

**Credentials and URLs** — pull from env, never inline:

```typescript
// CORRECT
baseUrl: process.env.API_URL,
headers: process.env.ACCESS_TOKEN,
body: { email: process.env.APP_EMAIL, password: process.env.APP_PASSWORD },

// FORBIDDEN
baseUrl: 'https://api.example.com',
headers: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
```

Use enums for endpoint paths:

```typescript
import { ApiEndpoints } from '../../../enums/app/app';

url: ApiEndpoints.LOGIN,
```

### Phase 4: Wrap multi-call tests in `test.step`

**MANDATORY:** When a test contains more than one API call, each call **MUST** be wrapped in a dedicated `test.step()` with:

1. A descriptive name indicating the API operation
2. Proper validation based on the context (status code, schema, specific fields)

This improves:

- **Readability** — Clear flow of API operations
- **Reporting** — Detailed step-by-step execution traces
- **Debugging** — Pinpoint which API call failed

**Correct pattern:**

```typescript
test(
    'should create and verify user workflow',
    { tag: '@api' },
    async ({ apiRequest }) => {
        const userData = generateUser();
        let userId: string;

        await test.step('Create user via POST /api/users', async () => {
            const { status, body } = await apiRequest<UserResponse>({
                method: 'POST',
                url: '/api/users',
                baseUrl: process.env.API_URL,
                headers: process.env.ACCESS_TOKEN,
                body: userData,
            });

            expect(status).toBe(201);
            expect(UserResponseSchema.parse(body)).toBeTruthy();
            userId = body.id;
        });

        await test.step('Retrieve user via GET /api/users/:id', async () => {
            const { status, body } = await apiRequest<UserResponse>({
                method: 'GET',
                url: `/api/users/${userId}`,
                baseUrl: process.env.API_URL,
                headers: process.env.ACCESS_TOKEN,
            });

            expect(status).toBe(200);
            expect(UserResponseSchema.parse(body)).toBeTruthy();
            expect(body.id).toBe(userId);
            expect(body.email).toBe(userData.email);
        });

        await test.step('Delete user via DELETE /api/users/:id', async () => {
            const { status, body } = await apiRequest<null>({
                method: 'DELETE',
                url: `/api/users/${userId}`,
                baseUrl: process.env.API_URL,
                headers: process.env.ACCESS_TOKEN,
            });

            expect(status).toBe(204);
            expect(body).toBeNull();
        });
    }
);
```

**Forbidden pattern:** multiple API calls inside a single `test` body **without** `test.step` wrappers — the trace shows one big test, debugging which call failed requires reading the assertions, and reporting can't surface create-vs-get-vs-delete structure.

**Single API call exception:** If a test contains **only one** API call, `test.step` is optional but recommended for consistency.

### Phase 5: Cover the full status-code matrix

For every endpoint × HTTP method combination, tests **MUST** cover **every status code listed in the OpenAPI spec** plus the baseline scenarios below. If the OpenAPI spec lists a status code not in this table, it still requires a test.

| Scenario                                    | Status  | What to assert                                                                    |
| ------------------------------------------- | ------- | --------------------------------------------------------------------------------- |
| Happy path (valid auth + valid body)        | 200/201 | Schema parse passes + key fields match sent data                                  |
| Missing Authorization header                | 401     | `status === 401`, validate body with schema or `expect(body).toBeNull()`          |
| Insufficient permissions (wrong-role token) | 403     | `status === 403`, validate body with schema or `expect(body).toBeNull()`          |
| Empty body (for POST/PUT/PATCH)             | 400/422 | Error schema parse passes — single test with `{}` body                            |
| Each required field omitted individually    | 400/422 | One test per field via destructure + rest — see Phase 6                           |
| Each field with type-inappropriate values   | 400/422 | `for...of` loop per field — see Phase 6                                           |
| Non-existent resource ID                    | 404     | `status === 404` (use `test.skip` with `// FIXME` comment if backend bug exists)  |
| Invalid path parameter formats              | 404     | Data-driven loop: numeric string, boolean-like, special chars, injection attempts |
| Unsupported HTTP method                     | 405     | At least one test with a method the endpoint does not support                     |
| Conflict (if listed in OpenAPI)             | 409     | Test the conflicting condition or `test.skip` with `// FIXME` if not reproducible |
| Validation errors (if listed in OpenAPI)    | 422     | Covered by per-field validation tests above                                       |
| No content (for DELETE)                     | 204     | `status === 204`, `expect(body).toBeNull()`                                       |

**Structure:** One `test.describe` per HTTP method + path. Use `beforeAll`/`afterAll` (not `beforeEach`/`afterEach`) to create/delete shared resources needed by multiple tests in the same describe block.

**Key conventions from real tests:**

- Auth tokens: `process.env.ACCESS_TOKEN` (full permissions), `process.env.ACCESS_TOKEN_ZERO` (zero permissions)
- Config: `process.env.API_URL` + `/api/X` — never bare `process.env.API_URL`
- Cleanup: `afterAll` in POST describes (holds `resourceId` from the happy-path test); `afterAll` in GET/PUT/DELETE describes (resource created in `beforeAll`)
- When a `test.skip` is needed due to a backend bug: add `// FIXME: <ticket-url>` comment + `/* eslint-disable playwright/no-skipped-test */` above it
- Tag: `@api` for API tests (check real tag in existing spec files for other areas)

### Phase 6: Add per-field negative / validation coverage

Testing only with an empty body (`{}`) is never sufficient. Every endpoint that accepts a request body (POST, PUT, PATCH) requires systematic per-field validation testing.

**Coverage checklist for endpoints with a body:**

1. **Empty body** — single test sending `{}`
2. **Each required field omitted** — one test per field, omitting only that field while keeping all others valid
3. **Each field with type-inappropriate values** — `for...of` loop per field using contextually appropriate invalid values
4. **Boundary values** where applicable (empty string for min-length, negative for positive-only numbers, past dates for future-only, etc.)

**Universal invalid arrays** live as `as const` exports in `test-data/static/util/invalid-values.ts` — `INVALID_STRING_VALUES`, `INVALID_UUID_VALUES`, `INVALID_NUMBER_VALUES`, `INVALID_BOOLEAN_VALUES`, `INVALID_ENUM_VALUES`, `INVALID_ARRAY_VALUES`, `INVALID_OBJECT_VALUES`. **Always import**; never redefine inline.

**Patterns to use:**

- **`for...of` spread-and-override** — base valid payload, override one field at a time with `INVALID_*` values, assert `400` + `BadRequestResponseSchema.parse(body)`.
- **Omitting required fields** — destructure + rest (`const { [field]: _, ...rest } = validPayload`) per required field.
- **Path-parameter validation** — data-driven loop over `[{ description, value }]` with numeric strings, boolean-likes, special chars, injection attempts. **Mandatory regardless of OpenAPI mention.**

**Three-tier rule for _where_ invalid-value arrays live:**

1. **Universal type-mismatch arrays** → `test-data/static/util/invalid-values.ts` (`INVALID_*` `as const` tuples). Import; never redefine.
2. **Domain-specific curated invalid sets** (invalid emails, weak passwords, forbidden categories) → `test-data/static/{area}/*.ts` (`as const`). Import; never inline. Never `.json`.
3. **Field-specific boundary / range values** used in exactly one field → **inline** in the spec. Promote to static data only when reused across 2+ fields or spec files.

A typical validation describe combines tier 1 and tier 3 in separate `for...of` loops.

**Forbidden: empty-body-only validation.** A single `body: {}` test asserting `400` is **not** sufficient. Per-field omission and per-field invalid-type loops are mandatory.

### Phase 7: Handle behavior mismatches

When the API's actual behavior differs from the OpenAPI spec or from the expected status code in the Phase 5 coverage matrix:

1. **NEVER silently drop the test.** The test must exist in the file.
2. **Write the test as the spec says it should work** (expected status code and schema).
3. **Wrap it with `test.skip`** and add a `// FIXME:` comment explaining the discrepancy:

```typescript
/* eslint-disable playwright/no-skipped-test */
// FIXME: API returns 500 instead of 422 for invalid price on PUT. Backend bug.
test.skip(
    'should return 422 when price is a non-numeric string',
    { tag: '@api' },
    async ({ apiRequest }) => {
        // ... test body as it SHOULD work per spec ...
    }
);
```

4. **Never adjust the expected status code to match buggy behavior.** The test documents the contract, not the current bug.
5. **If the API returns a different valid status code than the spec** (e.g., 422 instead of 400), use the actual status code and add a comment noting the spec discrepancy.

### Phase 8: (When needed) Promote to a helper fixture

For **critical, recurring setup/teardown operations** that multiple tests depend on (e.g., creating a user account that several test files need as a precondition, or seeding complex data that must be cleaned up), use helper fixtures in `fixtures/helper/helper-fixture.ts`.

Helper fixtures wrap the `apiRequest` plain function with Playwright's fixture lifecycle: setup before `await use(...)`, yield via `use(data)`, teardown after — runs even if the test fails.

**When to use `apiRequest` fixture vs. helper fixture:**

| Approach                                | Use Case                                                                        | Example                                                    |
| --------------------------------------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **`apiRequest` fixture** (primary)      | All API calls in tests — assertions, `beforeEach`/`afterEach`, one-off calls    | Validate status codes, response schemas, teardown in hooks |
| **Helper fixture** (important ops only) | Critical setup/teardown reused across many test files with guaranteed lifecycle | Seed a user account that 10+ test files depend on          |
| **Factory function**                    | Generate dynamic test data (no API call)                                        | `generateUser()` from `test-data/factories/`               |

**Rule of thumb:** Use `apiRequest` directly unless you find yourself copy-pasting the same multi-step setup/teardown into 3+ test files.

## API Architecture

```
fixtures/
├── api/
│   ├── api-request-fixture.ts    ← Playwright fixture providing apiRequest (used in tests via DI)
│   ├── plain-function.ts         ← Core HTTP function (internal implementation, used by fixture and helpers)
│   ├── api-types.ts              ← TypeScript types (ApiRequestParams, ApiRequestResponse, etc.)
│   └── schemas/                  ← Zod schemas for validation
│       ├── app/                  ← App-specific schemas
│       └── util/                 ← Shared error response schemas
└── helper/
    └── helper-fixture.ts         ← Setup/teardown fixtures for important recurring operations
```

- `api-request-fixture.ts` — Playwright fixture wrapping the plain function. Provides `apiRequest` via DI with generics for type-safe responses. **Primary tool for API calls in tests.**
- `plain-function.ts` — Core HTTP function. Handles method routing, auth headers, response parsing. Used internally by the fixture and by helper fixtures.
- `api-types.ts` — Shared types: `ApiRequestParams`, `ApiRequestResponse<T>`, `ApiRequestFn`.
- `helper-fixture.ts` — Setup/teardown fixtures for important, recurring preconditions. Uses `plain-function.ts` internally.

## See Also

- **`type-safety`** skill — Zod 4 schemas, `z.strictObject()`, the mandatory `expect(SchemaName.parse(body)).toBeTruthy();` pattern, `zOutput` / `zInput` inference.
- **`data-strategy`** skill — Faker + Zod factories for happy-path payloads, the three-tier rule for negative testing (universal `INVALID_*` arrays + domain-specific sets + inline boundary values).
- **`enums`** skill — `ApiEndpoints.*` for endpoint paths and error message constants used in assertions.
- **`fixtures`** skill — the `apiRequest` fixture itself, helper fixtures for setup/teardown, and the 3+ files rule of thumb for promotion (Phase 8).
- **`helpers`** skill — auth bootstrap (`createAppStorageState`, `setUserAccessToken`) that publishes `process.env.ACCESS_TOKEN` consumed by API tests.
- **`test-standards`** skill — `@api` tag, `test.step` requirements for multi-call tests, single-tag rule.
- **`refactor-values`** skill — when an endpoint enum value or a Zod literal needs to change, the impact-analysis workflow.
