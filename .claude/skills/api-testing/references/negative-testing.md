# Negative testing

Loops for the 400/422 and 404 rows of the coverage matrix. `ApiEndpoints.PRODUCTS` and `generateProduct()` are illustrative: define the enum member (`enums`) and the factory (`data-strategy`) first. Status and error schema come from the contract; the demo API answers validation errors with 422 and `UnprocessableEntityResponseSchema` from `fixtures/api/schemas/util/errorResponseSchema.ts`.

Three tiers of invalid data, owned by `data-strategy`: the universal type-mismatch arrays (`INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, `INVALID_BOOLEAN_VALUES`, `INVALID_UUID_VALUES`, `INVALID_ENUM_VALUES`, `INVALID_ARRAY_VALUES`, `INVALID_OBJECT_VALUES`) are imported from `test-data/static/util/invalid-values.ts`; a domain set (malformed emails) comes from `test-data/static/{area}/`; a range violation specific to one field stays inline in the spec.

## Invalid-type loop (spread-and-override)

One valid payload as the base, one field overridden per loop. Repeat the loop per field with the matching `INVALID_*` array; an `email` field gets a second loop over the domain set. For an optional field drop `undefined` from the array (`INVALID_STRING_VALUES.filter((value) => value !== undefined)`): omitting an optional field is valid input, and the omission loop already covers the required ones.

```typescript
import { ApiEndpoints } from '../../../enums/app/app';
import {
    UnprocessableEntityResponse,
    UnprocessableEntityResponseSchema,
} from '../../../fixtures/api/schemas/util/errorResponseSchema';
import { expect, test } from '../../../fixtures/pom/test-options';
import { generateProduct } from '../../../test-data/factories/app/product.factory';
import { INVALID_STRING_VALUES } from '../../../test-data/static/util/invalid-values';

test.describe('POST /products - validation', () => {
    const validPayload = generateProduct();

    for (const invalidValue of INVALID_STRING_VALUES) {
        test(
            `should return 422 when name is ${JSON.stringify(invalidValue)}`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { status, body } =
                    await apiRequest<UnprocessableEntityResponse>({
                        method: 'POST',
                        url: ApiEndpoints.PRODUCTS,
                        baseUrl: process.env.API_URL,
                        headers: process.env.ACCESS_TOKEN,
                        body: { ...validPayload, name: invalidValue },
                    });

                expect(status).toBe(422);
                expect(
                    UnprocessableEntityResponseSchema.parse(body)
                ).toBeTruthy();
            }
        );
    }
});
```

An inline range set for one field takes the same loop: `const outOfRangeRatings = [-1, 0, 5.01, 1000];` for a `rating` constrained to 1..5. The empty-body test is one more test in the block with `body: {}`.

## Omission loop

One test per required field, removing only that field with destructure + rest.

```typescript
test.describe('POST /products - missing required fields', () => {
    const validPayload = generateProduct();
    const requiredFields = ['name', 'price', 'category'] as const;

    for (const field of requiredFields) {
        test(
            `should return 422 when ${field} is missing`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { [field]: _, ...payloadWithoutField } = validPayload;

                const { status, body } =
                    await apiRequest<UnprocessableEntityResponse>({
                        method: 'POST',
                        url: ApiEndpoints.PRODUCTS,
                        baseUrl: process.env.API_URL,
                        headers: process.env.ACCESS_TOKEN,
                        body: payloadWithoutField,
                    });

                expect(status).toBe(422);
                expect(
                    UnprocessableEntityResponseSchema.parse(body)
                ).toBeTruthy();
            }
        );
    }
});
```

## Path-parameter loop

Every path parameter, whether or not the contract mentions invalid formats. Send the auth header when the endpoint needs it, otherwise a 401 masquerades as 404 coverage.

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
            const { status, body } = await apiRequest<NotFoundResponse>({
                method: 'GET',
                url: `${ApiEndpoints.PRODUCTS}/${encodeURIComponent(value)}`,
                baseUrl: process.env.API_URL,
                headers: process.env.ACCESS_TOKEN,
            });

            expect(status).toBe(404);
            expect(NotFoundResponseSchema.parse(body)).toBeTruthy();
        }
    );
}
```

## Query-parameter loop

For documented query parameters (pagination, filters, sorting) compose the query onto the enum path, `` `${ApiEndpoints.PRODUCTS}?page=${value}` ``: the enum owns the path, the contract owns the parameter values. Cover an invalid type per parameter (`page=abc`, `limit=-1`), out-of-range values, and unknown parameters when the contract defines their behaviour. A list response (data array plus pagination metadata) gets its own `z.strictObject` schema like any other response.
