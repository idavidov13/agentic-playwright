# Zod usage

Zod 4 (`zod` 4.x, imported as `zod/v4`). The live schemas are `fixtures/api/schemas/app/userSchema.ts` and `fixtures/api/schemas/util/errorResponseSchema.ts`.

## Validator per data type

| Data type           | Validator                           | Example                                               |
| ------------------- | ----------------------------------- | ----------------------------------------------------- |
| UUID                | `z.uuid()`                          | `id: z.uuid()`                                        |
| GUID (permissive)   | `z.guid()`                          | `id: z.guid()`                                        |
| Email               | `z.email()`                         | `email: z.email()`                                    |
| URL                 | `z.url()`                           | `website: z.url()`                                    |
| Non-empty string    | `z.string().min(1)`                 | `name: z.string().min(1)`                             |
| Integer             | `z.int()`                           | `expires_in: z.int()`                                 |
| Positive number     | `z.number().positive()`             | `price: z.number().positive()`                        |
| Enum                | `z.enum([...])` or `z.enum(MyEnum)` | `role: z.enum(Roles)`                                 |
| Literal             | `z.literal(...)`                    | `statusCode: z.literal(200)`                          |
| Optional / nullable | `.optional()` / `.nullable()`       | `avatar: z.url().optional()`                          |
| Array               | `z.array(...)`                      | `items: z.array(ItemSchema)`                          |
| Record              | `z.record(z.string(), ...)`         | `errors: z.record(z.string(), z.array(z.string()))`   |
| Union               | `z.union([...])`                    | `message: z.union([z.string(), z.array(z.string())])` |
| ISO date / datetime | `z.iso.date()` / `z.iso.datetime()` | `createdAt: z.iso.datetime()`                         |
| IPv4, Base64        | `z.ipv4()`, `z.base64()`            | `ip: z.ipv4()`                                        |

## Zod 4 idioms versus project conventions

Zod 4 idioms (the old forms still work but are deprecated; prefer the new ones):

- `z.string().email()` → `z.email()`, `z.string().uuid()` → `z.uuid()`, `z.string().url()` → `z.url()`
- `z.nativeEnum(E)` → `z.enum(E)`
- `A.merge(B)` → `A.extend(B.shape)`
- `.passthrough()` → `z.looseObject()`, only where the contract allows unknown keys

Project conventions (this scaffold's rules, not Zod deprecations; do not "fix" external code for them):

- `z.object()` → `z.strictObject()` for every API schema (the Constitution checks reject `z.object()` under `fixtures/api/schemas/`)
- `z.infer<typeof S>` → `zOutput<typeof S>`, with `zInput<typeof S>` for the pre-parse shape

## `zInput` versus `zOutput`

`zOutput` is the shape after parsing (defaults applied, transforms run): response types and almost every consumer. `zInput` is the shape before parsing: request builders where the caller may omit a defaulted field. Without `.default()` or `.transform()` the two are identical; use `zOutput`.

```typescript
import { z } from 'zod/v4';
import type { input as zInput, output as zOutput } from 'zod/v4';

const SignupSchema = z.strictObject({
    email: z.email(),
    role: z.enum(['admin', 'user']).default('user'),
});

type SignupInput = zInput<typeof SignupSchema>; // { email: string; role?: 'admin' | 'user' }
type SignupOutput = zOutput<typeof SignupSchema>; // { email: string; role: 'admin' | 'user' }

function buildSignup(input: SignupInput): SignupOutput {
    return SignupSchema.parse(input);
}
```

## Envelope extraction

Below the threshold every response schema spells its envelope out:

```typescript
export const CreateProductResponseSchema = z.strictObject({
    success: z.boolean(),
    message: z.string(),
    data: ProductSchema,
    errors: z.unknown().nullable(),
});
```

Past the threshold, one per-domain file and `.extend()`, which keeps the strict config:

```typescript
// fixtures/api/schemas/{area}/_envelope.ts
export const EnvelopeSchema = z.strictObject({
    success: z.boolean(),
    message: z.string(),
    errors: z.unknown().nullable(),
});

// fixtures/api/schemas/{area}/productSchema.ts
export const CreateProductResponseSchema = EnvelopeSchema.extend({
    data: ProductSchema,
});
```
