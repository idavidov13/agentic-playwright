# Per-Field Negative Testing — Patterns and Three-Tier Data Rule

Long-form examples + invalid-value reference for `api-testing/SKILL.md` Phase 6. The Critical rules and the coverage checklist stay inline in `SKILL.md`; this file holds the verbose per-field patterns, the universal `INVALID_*` constants table, and the three-tier rule for _where_ invalid arrays live.

## Type-specific invalid values (universal arrays)

Universal type-mismatch sets live as `as const` exports in `test-data/static/util/invalid-values.ts` and **must** be imported — never redefined inline.

| Field Type          | Constant                 | Values                                       |
| ------------------- | ------------------------ | -------------------------------------------- |
| `string` (required) | `INVALID_STRING_VALUES`  | `[123, true, null, undefined]`               |
| `string` (uuid)     | `INVALID_UUID_VALUES`    | `['not-a-uuid', '', 123, null, undefined]`   |
| `number`            | `INVALID_NUMBER_VALUES`  | `['string', '123', true, null, undefined]`   |
| `boolean`           | `INVALID_BOOLEAN_VALUES` | `['yes', 1, 0, null, undefined]`             |
| `enum`              | `INVALID_ENUM_VALUES`    | `['invalidValue', '', 123, null, undefined]` |
| `array`             | `INVALID_ARRAY_VALUES`   | `['string', 123, null, undefined, {}]`       |
| `object` (nested)   | `INVALID_OBJECT_VALUES`  | `['string', 123, null, undefined, []]`       |

For `string` (email) fields, combine `INVALID_STRING_VALUES` (for type mismatch) with domain-specific email-format violations from `test-data/static/{area}/` — two separate `for...of` loops.

A number field should be tested with a string, a stringified number (`'123'`), a boolean, null, and undefined. A boolean field should be tested with a truthy string, numeric truthy/falsy, null, and undefined. Each type has its own realistic set of "wrong" values.

## Pattern: `for...of` with spread-and-override

Use a valid payload as the base, then override one field at a time with invalid values. This isolates the field under test:

```typescript
import { generateProduct } from '../../../test-data/factories/app/product.factory';
import {
    BadRequestResponse,
    BadRequestResponseSchema,
} from '../../../fixtures/api/schemas/util/errorResponseSchema';
import {
    INVALID_NUMBER_VALUES,
    INVALID_STRING_VALUES,
} from '../../../test-data/static/util/invalid-values';

test.describe('POST /api/products - validation', () => {
    const validPayload = generateProduct();

    for (const invalidValue of INVALID_STRING_VALUES) {
        test(
            `should return 400 when name is ${JSON.stringify(invalidValue)}`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { status, body } = await apiRequest<BadRequestResponse>({
                    method: 'POST',
                    url: ApiEndpoints.PRODUCTS,
                    baseUrl: process.env.API_URL,
                    headers: process.env.ACCESS_TOKEN,
                    body: { ...validPayload, name: invalidValue },
                });

                expect(status).toBe(400);
                expect(BadRequestResponseSchema.parse(body)).toBeTruthy();
            }
        );
    }

    for (const invalidValue of INVALID_NUMBER_VALUES) {
        test(
            `should return 400 when price is ${JSON.stringify(invalidValue)}`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { status, body } = await apiRequest<BadRequestResponse>({
                    method: 'POST',
                    url: ApiEndpoints.PRODUCTS,
                    baseUrl: process.env.API_URL,
                    headers: process.env.ACCESS_TOKEN,
                    body: { ...validPayload, price: invalidValue },
                });

                expect(status).toBe(400);
                expect(BadRequestResponseSchema.parse(body)).toBeTruthy();
            }
        );
    }

    // Inline is acceptable here: these are field-specific range violations for
    // `rating` (constrained to 1..5) and are not reusable anywhere else.
    const outOfRangeRatings = [-1, 0, 0.99, 5.01, 6, 1000];
    for (const invalidValue of outOfRangeRatings) {
        test(
            `should return 400 when rating is out of range (${invalidValue})`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { status, body } = await apiRequest<BadRequestResponse>({
                    method: 'POST',
                    url: ApiEndpoints.PRODUCTS,
                    baseUrl: process.env.API_URL,
                    headers: process.env.ACCESS_TOKEN,
                    body: { ...validPayload, rating: invalidValue },
                });

                expect(status).toBe(400);
                expect(BadRequestResponseSchema.parse(body)).toBeTruthy();
            }
        );
    }
});
```

## Pattern: omitting required fields

To test that each required field triggers a 400 when missing, omit one field at a time using destructure + rest:

```typescript
test.describe('POST /api/products - missing required fields', () => {
    const validPayload = generateProduct();

    const requiredFields = ['name', 'price', 'category'] as const;
    for (const field of requiredFields) {
        test(
            `should return 400 when ${field} is missing`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { [field]: _, ...payloadWithoutField } = validPayload;

                const { status, body } = await apiRequest<BadRequestResponse>({
                    method: 'POST',
                    url: ApiEndpoints.PRODUCTS,
                    baseUrl: process.env.API_URL,
                    headers: process.env.ACCESS_TOKEN,
                    body: payloadWithoutField,
                });

                expect(status).toBe(400);
                expect(BadRequestResponseSchema.parse(body)).toBeTruthy();
            }
        );
    }
});
```

## Pattern: path parameter validation

For every endpoint with a path parameter (e.g., `/products/{productId}`), test with invalid formats using a data-driven loop:

```typescript
const invalidProductIds = [
    { description: 'numeric string', value: '99999' },
    { description: 'boolean-like string', value: 'true' },
    { description: 'special characters', value: '<script>' },
    { description: 'SQL injection attempt', value: '1 OR 1=1' },
];
for (const { description, value } of invalidProductIds) {
    test(
        `should return 404 for invalid productId - ${description}`,
        { tag: '@api' },
        async ({ apiRequest }) => {
            const { status } = await apiRequest<ItemNotFoundResponse>({
                method: 'GET',
                url: `${ApiEndpoints.PRODUCTS}/${encodeURIComponent(value)}`,
                baseUrl: process.env.API_URL,
            });

            expect(status).toBe(404);
        }
    );
}
```

This is **not optional**. Every path parameter needs these tests regardless of whether the OpenAPI spec mentions them.

## Three-tier rule — where invalid-value arrays live

1. **Universal type-mismatch arrays** (values that are wrong for any field of a given primitive type) — **must** live in `test-data/static/util/invalid-values.ts` as exported `as const` tuples (`INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, `INVALID_BOOLEAN_VALUES`, `INVALID_UUID_VALUES`, `INVALID_ENUM_VALUES`, `INVALID_ARRAY_VALUES`, `INVALID_OBJECT_VALUES`). The file must be `.ts`, not `.json`, so it can represent `undefined`. Spec files import and iterate — **never** redefine inline.
2. **Domain-specific curated invalid values** (invalid email formats, password policy violations, invalid locales, forbidden product categories, etc.) — live under `test-data/static/{area}/` as `.ts` with `as const` exports, following the existing `invalidCredentials.ts` precedent (`INVALID_EMAILS`, `INVALID_PASSWORDS`, `INVALID_LOGIN_ATTEMPTS`). Also imported, never inline. Never `.json`.
3. **Field-specific boundary / constraint values** (e.g., out-of-range values for a `number` field constrained to `1..5`: `[-1, 0, 0.99, 5.01, 6, 1000]`) — **may stay inline** in the spec file when the set is meaningful to exactly one field and promoting it (e.g., `INVALID_NUMBER_VALUES_1_TO_5`) would be over-engineering. If the same boundary set is needed in 2+ fields or spec files, promote it to static data.

A single validation describe typically combines tier 1 and tier 3 in separate `for...of` loops: one iterating `INVALID_NUMBER_VALUES` for type mismatch, another iterating an inline array for range violations.
