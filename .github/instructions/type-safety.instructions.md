---
applyTo: '**/*.ts'
---

# Type Safety

## Critical

- **NEVER** use `any`. Use explicit types, Zod-inferred types (`zOutput<typeof ...>`), or `unknown` at boundaries.
- **NEVER** use `as T` or `as unknown as T` to silence the type-checker. If you genuinely need to cross a type boundary, validate first (`Schema.parse(...)`) and let Zod produce the typed result.
- **ALWAYS** define API schemas with `z.strictObject()`. `z.object()` silently strips unknown keys and hides contract drift.
- **ALWAYS** prefer Zod 4 top-level validators (`z.uuid()`, `z.email()`, `z.url()`, `z.int()`, `z.enum(E)`) over the deprecated chained forms (`z.string().uuid()`, `z.string().email()`, etc.).
- **ALWAYS** assert API responses with the exact pattern `expect(SchemaName.parse(body)).toBeTruthy();`. `Schema.parse(body)` on its own is not enough.
- **ALWAYS** specify explicit return types on exported and public functions (`Promise<void>`, `Promise<UserResponse>`, `Locator`, `string`, etc.).
- **Access `process.env.*` with `!` (guaranteed at runtime) or `??` (with a safe fallback).** Never let `string | undefined` leak into downstream code.
- **Build response schemas directly from the documented contract.** Define each field — including the response envelope (`success / message / data / errors` or whatever the API uses) — explicitly per endpoint, exactly as the OpenAPI / Swagger spec describes. Do not invent factories or helpers that hide the envelope. If an envelope is genuinely repeated across many endpoints in one domain, extract a per-domain shared `z.strictObject` definition (e.g. `fixtures/api/schemas/{area}/_envelope.ts`) and compose with `.extend(...)` — but only after the repetition is real and observed.

## Schema Location

```
fixtures/api/schemas/
├── {area}/        ← App-specific schemas (user, product, etc.) — run `ls fixtures/api/schemas/` to find the real subdirectory
│   └── userSchema.ts
└── util/          ← Shared error response schemas
    └── errorResponseSchema.ts
```

## Instructions

### Phase 1: Rule out `any` and unsafe casts

The TypeScript project is `"strict": true`. That configuration exists to surface bad types; don't work around it.

```typescript
// FORBIDDEN
const data: any = await response.json();
function process(input: any): any {
    /* ... */
}
const user = raw as UserResponse;
const user = raw as unknown as UserResponse;

// CORRECT
const raw: unknown = await response.json();
const user = UserResponseSchema.parse(raw); // Zod validates + types
function process(input: unknown): ProcessedResult {
    /* ... */
}
```

Rules:

- `unknown` is the right type at a **boundary** (network, file read, user input) — convert to a concrete type via `Schema.parse(...)`.
- Inside a function body, every variable must have a concrete type (explicit or inferred from a typed source).
- `as T` is a red flag. If you see one, ask: _"Can I parse with Zod here instead?"_ The answer is almost always yes.

### Phase 2: Define the Zod schema

Use `z.strictObject()` and Zod 4 top-level validators. Build the response schema — including the envelope — directly from the OpenAPI / Swagger documentation. Each schema is a self-contained 1:1 mirror of the documented contract.

```typescript
import { z } from 'zod/v4';
import type { output as zOutput, input as zInput } from 'zod/v4';

// 1. Define the domain schema with strict validation
export const UserSchema = z.strictObject({
    id: z.uuid(),
    email: z.email(),
    token: z.string().min(1),
    role: z.enum(['admin', 'user', 'guest']),
    avatar: z.url().optional(),
});

// 2. Wrap with the response envelope exactly as the spec describes it.
//    Spell every field out — no factory helper. If many endpoints in this
//    domain share the same envelope, extract a per-domain `_envelope.ts`
//    `z.strictObject` and compose with `.extend(...)` (only after the
//    repetition is real).
export const UserResponseSchema = z.strictObject({
    success: z.boolean(),
    message: z.string(),
    data: UserSchema,
    errors: z.unknown().nullable(),
});
```

```typescript
// FORBIDDEN -- z.object() silently strips unknown keys
export const Schema = z.object({
    /* ... */
});

// CORRECT -- z.strictObject() rejects unknown keys at runtime
export const Schema = z.strictObject({
    /* ... */
});
```

### Phase 3: Infer the TypeScript type from the schema

Zod 4 exposes two inference helpers. Pick based on whether you want the shape **before** or **after** transforms / defaults:

- **`zOutput<typeof Schema>`** — the type after parsing (defaults applied, transforms run). Use this for response types and 99% of schema consumers.
- **`zInput<typeof Schema>`** — the type before parsing (defaults optional, pre-transform values accepted). Use this for form payloads or request bodies where the caller may omit defaulted fields.

```typescript
import type { output as zOutput, input as zInput } from 'zod/v4';

export type User = zOutput<typeof UserSchema>;
export type UserResponse = zOutput<typeof UserResponseSchema>;

// Example where Input and Output differ -- a schema with a default:
const SignupSchema = z.strictObject({
    email: z.email(),
    role: z.enum(['admin', 'user']).default('user'),
});

type SignupInput = zInput<typeof SignupSchema>; // { email: string; role?: 'admin' | 'user' }
type SignupOutput = zOutput<typeof SignupSchema>; // { email: string; role: 'admin' | 'user' }
```

If there are no `.default(...)` or `.transform(...)` calls, `zInput` and `zOutput` produce the same type — still prefer `zOutput` for clarity.

### Phase 4: Validate at runtime with the mandatory assertion

API response validation uses the exact assertion pattern enforced across the scaffold:

```typescript
import {
    UserResponse,
    UserResponseSchema,
} from '../../../fixtures/api/schemas/app/userSchema';

const { status, body } = await apiRequest<UserResponse>({
    /* ... */
});

expect(status).toBe(200);
expect(UserResponseSchema.parse(body)).toBeTruthy();
```

- The generic `<UserResponse>` gives compile-time safety on `body`.
- `expect(SchemaName.parse(body)).toBeTruthy();` is the mandatory runtime check — not `schema.parse(body)` alone, not a bare `SchemaName.parse(body)` with no assertion.
- If the response is legitimately `null` (e.g., a 204 `DELETE`), assert `expect(body).toBeNull()` instead — do not call `parse()` on `null`.

This pattern is enforced in the `api-testing` Critical rule and repeated by `helpers` and `test-standards`. Any helper, fixture, or spec that calls `apiRequest` follows it.

### Phase 5: Annotate function signatures

Always specify return types on public / exported functions. TypeScript can often infer them, but an explicit annotation documents the contract and surfaces breaking changes earlier.

```typescript
// CORRECT
async submit(): Promise<void> { /* ... */ }
async getData(): Promise<UserResponse> { /* ... */ }
get submitButton(): Locator { /* ... */ }
export function formatDate(value: number | string): string { /* ... */ }

// AVOID -- return type missing
async submit() { /* ... */ }
```

Parameter types must also be explicit — never rely on `noImplicitAny` to rescue a missing annotation.

### Phase 6: Handle `process.env.*` correctly

`process.env.X` is always typed as `string | undefined`. Two sanctioned patterns:

```typescript
// Pattern A -- non-null assertion: use when the value is guaranteed at runtime
// (e.g., after auth bootstrap, or because the key is in env/.env.example).
const url = process.env.APP_URL!;

// Pattern B -- fallback: use when a sensible default exists or the value is
// truly optional.
const environment = process.env.ENVIRONMENT ?? 'dev';
const timeout = Number(process.env.TIMEOUT_MS ?? 10000);
```

Never let `string | undefined` spread into downstream code unchecked:

```typescript
// FORBIDDEN -- downstream consumers will get `string | undefined`
export const baseUrl = process.env.API_URL;

// CORRECT -- force the resolution at the access point
export const baseUrl = process.env.API_URL!;
// or
export const baseUrl = process.env.API_URL ?? 'http://localhost:3000';
```

**NEVER** hardcode secrets, passwords, or URLs. See the `config` skill for where env variables are declared.

```typescript
// FORBIDDEN
const password = 'secret123';

// CORRECT
const password = process.env.APP_PASSWORD!;
```

## Zod Validators Reference

Use the most specific Zod validator for each field. Zod 4 promotes string format validators to top-level APIs:

| Data Type         | Validator           | Example                                               |
| ----------------- | ------------------- | ----------------------------------------------------- |
| UUID              | `z.uuid()`          | `id: z.uuid()`                                        |
| GUID (permissive) | `z.guid()`          | `id: z.guid()`                                        |
| Email             | `z.email()`         | `email: z.email()`                                    |
| URL               | `z.url()`           | `website: z.url()`                                    |
| Non-empty         | `z.string().min(1)` | `name: z.string().min(1)`                             |
| Integer           | `z.int()`           | `count: z.int()`                                      |
| Enum              | `z.enum([...])`     | `role: z.enum(['admin', 'user'])`                     |
| Native Enum       | `z.enum(MyEnum)`    | `role: z.enum(Roles)`                                 |
| Literal           | `z.literal(...)`    | `statusCode: z.literal(200)`                          |
| Optional          | `.optional()`       | `avatar: z.url().optional()`                          |
| Array             | `z.array(...)`      | `items: z.array(ItemSchema)`                          |
| Union             | `z.union([...])`    | `message: z.union([z.string(), z.array(z.string())])` |
| ISO Date          | `z.iso.date()`      | `date: z.iso.date()`                                  |
| ISO DateTime      | `z.iso.datetime()`  | `createdAt: z.iso.datetime()`                         |
| IPv4              | `z.ipv4()`          | `ip: z.ipv4()`                                        |
| Base64            | `z.base64()`        | `data: z.base64()`                                    |

### Zod 4 deprecations

The chained forms still work but prefer the top-level forms:

- `z.string().email()` → `z.email()`
- `z.string().uuid()` → `z.uuid()`
- `z.string().url()` → `z.url()`
- `z.nativeEnum(E)` → `z.enum(E)`
- `z.object()` → `z.strictObject()` (**mandatory** for this project — rejects unknown keys)
- `z.object().merge()` → **removed**; use `.extend()` on `z.strictObject()` or spread `{ ...A.shape, ...B.shape }`
- `z.object().passthrough()` → `z.looseObject()` (only when explicitly needed)
- `z.infer<typeof Schema>` → `zOutput<typeof Schema>` (use `zInput<>` for pre-transform types)

## TypeScript Strict Mode

The project uses `"strict": true` in `tsconfig.json`. Consequences:

- All parameters must have explicit types.
- Return types should be specified on public methods.
- No implicit `any`.
- Null checks are enforced (`strictNullChecks`).

Do not disable or weaken strict mode for a single file. If a type feels impossible to express, the shape is usually wrong — re-parse at the boundary with Zod.

## See Also

- **`api-testing`** skill — how schemas are consumed in tests, the full coverage matrix, `expect(Schema.parse(body)).toBeTruthy()` enforcement, Phase 7 behaviour-mismatch protocol.
- **`config`** skill — where env variables are declared (`env/.env.example`, dotenv loading) and the consumption decision for `!` vs `??`.
- **`data-strategy`** skill — Faker factories that return Zod-inferred types; factories call `Schema.parse(...)` internally to guarantee the output matches.
- **`refactor-values`** skill — safe workflow for changing enum values referenced by `z.literal(...)` or `z.enum([...])`; Anti-Pattern 4 forbids loosening schemas to accommodate drift.
- **`helpers`** skill — helpers that call APIs apply the same `expect(Schema.parse(body)).toBeTruthy()` pattern (Phase 5).
- **`debugging`** skill — when `expect(Schema.parse(body)).toBeTruthy()` throws `ZodError`, or when a `zInput` / `zOutput` mismatch produces an unexpected runtime error.
