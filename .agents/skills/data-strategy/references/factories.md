# Factories

Faker + Zod: unique, valid data per test run, so parallel workers never collide on a name, email or id. The live instance is `test-data/factories/app/user.factory.ts` (`generateUser`, `generateLoginCredentials`); `ProductSchema` and `generateProduct` below are illustrative.

## Pattern

```typescript
// test-data/factories/{area}/product.factory.ts
import { faker } from '@faker-js/faker';
import {
    Product,
    ProductSchema,
} from '../../../fixtures/api/schemas/app/productSchema';

/**
 * Generates a valid product with randomized data.
 * @param {Partial<Product>} overrides - Fields to pin for the test.
 * @returns {Product} A product that satisfies ProductSchema.
 */
export const generateProduct = (overrides?: Partial<Product>): Product => {
    const defaults: Product = {
        id: faker.string.uuid(),
        name: faker.commerce.productName(),
        price: faker.number.float({ min: 1, max: 500, fractionDigits: 2 }),
        inStock: faker.datatype.boolean(),
    };

    return ProductSchema.parse({ ...defaults, ...overrides });
};
```

Six requirements: `import { faker } from '@faker-js/faker'`; the schema from `fixtures/api/schemas/{area}/`; `overrides?: Partial<SchemaType>`; `Schema.parse(...)` on the merged object; the Zod-inferred return type; JSDoc with `@param` and `@returns` (a factory is an action-like function).

## Overrides

```typescript
const product = generateProduct();
const soldOut = generateProduct({ inStock: false });
```

Pin only the fields the test asserts on; everything else stays random.

## When `Schema.parse` throws inside the factory

The Faker defaults no longer satisfy the schema: a new required field, a changed format, a range. Fix the defaults. Never loosen the schema; it is the contract (`type-safety`).
