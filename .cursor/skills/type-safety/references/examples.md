# Type Safety — Worked Examples

## Example 1: Add a new schema, infer the type, validate in a test

```typescript
// fixtures/api/schemas/app/productSchema.ts
import { z } from 'zod/v4';
import type { output as zOutput } from 'zod/v4';

export const ProductSchema = z.strictObject({
    id: z.uuid(),
    name: z.string().min(1),
    price: z.number().positive(),
    category: z.enum(['electronics', 'clothing', 'food']),
    rating: z.int().min(1).max(5),
    inStock: z.boolean(),
});

// Response envelope spelled out per the OpenAPI contract -- no factory helper.
// If the envelope is repeated across many endpoints in this domain, extract a
// per-domain `_envelope.ts` and compose via `.extend(...)`.
export const CreateProductResponseSchema = z.strictObject({
    success: z.boolean(),
    message: z.string(),
    data: ProductSchema,
    errors: z.unknown().nullable(),
});

export type Product = zOutput<typeof ProductSchema>;
export type CreateProductResponse = zOutput<typeof CreateProductResponseSchema>;
```

```typescript
// tests/app/api/products.spec.ts
import {
    CreateProductResponse,
    CreateProductResponseSchema,
} from '../../../fixtures/api/schemas/app/productSchema';

test('should return 201 on create', { tag: '@api' }, async ({ apiRequest }) => {
    const { status, body } = await apiRequest<CreateProductResponse>({
        method: 'POST',
        url: ApiEndpoints.PRODUCTS,
        baseUrl: process.env.API_URL,
        headers: process.env.ACCESS_TOKEN,
        body: generateProduct(),
    });

    expect(status).toBe(201);
    expect(CreateProductResponseSchema.parse(body)).toBeTruthy();
});
```

## Example 2: `zInput` vs `zOutput` when a default is present

```typescript
import { z } from 'zod/v4';
import type { input as zInput, output as zOutput } from 'zod/v4';

const SignupSchema = z.strictObject({
    email: z.email(),
    role: z.enum(['admin', 'user']).default('user'),
});

type SignupInput = zInput<typeof SignupSchema>;
// -> { email: string; role?: 'admin' | 'user' }   -- role is optional on input

type SignupOutput = zOutput<typeof SignupSchema>;
// -> { email: string; role: 'admin' | 'user' }    -- role is always present after parse

// Use Input for request builders / form payloads where the caller may omit role:
function buildSignup(input: SignupInput): SignupOutput {
    return SignupSchema.parse(input);
}
```

If a schema has no `.default(...)` or `.transform(...)`, `zInput` and `zOutput` produce the same type — use `zOutput` for clarity.

## Example 3: Replace an `as T` cast with a Zod parse

```typescript
// BEFORE -- cast silences TypeScript but nothing validates the shape at runtime
const raw = await response.json();
const user = raw as UserResponse; // unsafe
const user2 = raw as unknown as UserResponse; // still unsafe, louder
console.log(user.email); // may be undefined

// AFTER -- parse at the boundary, get a typed, validated result
const raw: unknown = await response.json();
const user = UserResponseSchema.parse(raw); // type: UserResponse, validated at runtime
console.log(user.email); // definitely present
```
