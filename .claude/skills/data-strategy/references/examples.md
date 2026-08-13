# Data Strategy — Worked Examples

Three end-to-end walkthroughs aligned with the in-skill phases.

## Example 1: Add a factory for a new entity

User says: _"Add a factory for products and use it in the happy-path create test."_

Actions:

1. **Phase 1** — Happy-path dynamic data → Factory.
2. Confirm the Zod schema exists (`fixtures/api/schemas/{area}/productSchema.ts`); if not, follow the `api-testing` skill Phase 2 first.
3. **Phase 2** — Create `test-data/factories/{area}/product.factory.ts` with `generateProduct(overrides?)` using Faker + `ProductSchema.parse(...)`.
4. **Phase 4** — Import `generateProduct` in the spec; use the returned object as the request body or form input.
5. Apply Critical rules: no hardcoded names, JSDoc on the factory, return type is `zOutput<typeof ProductSchema>`.

## Example 2: Add a domain-specific invalid-values set

User says: _"Add invalid promo codes so we can check the promo-code field rejects them."_

Actions:

1. **Phase 1** — Curated invalid set specific to promo-code validation → Tier 2.
2. **Phase 3** — Create `test-data/static/{area}/invalidPromoCodes.ts` with either Shape A (`export const INVALID_PROMO_CODES = ['EXPIRED', 'TOOLONG...', ...] as const;`) or Shape B (`export const INVALID_PROMO_CODE_CASES = [{ description: '...', value: '...' }, ...] as const;`) depending on how the test consumes them.
3. **Phase 4** — Import the `as const` export and loop with `for...of` to generate one test per entry.
4. Do not combine these with universal type mismatches — keep Tier 1 (`INVALID_STRING_VALUES`) and Tier 2 in **separate** `for...of` loops.

## Example 3: Full negative-API coverage combining factory + universal + boundary

User says: _"Lock down validation for `POST /api/products`."_

Actions:

1. **Phase 1** — Multiple value kinds: happy-path base (factory), type-mismatch (Tier 1), out-of-range rating (Tier 3 inline).
2. **Phase 2** — Confirm `generateProduct()` exists; create it if not.
3. **Phase 4** — In the spec:
    - Use `generateProduct()` as the `validPayload` base.
    - Loop `INVALID_STRING_VALUES` for `name`, `INVALID_NUMBER_VALUES` for `price`, etc. (spread-and-override pattern from `api-testing` Phase 6).
    - Add a final inline loop `const outOfRangeRatings = [...]` for the `1..5` rating constraint.
4. Cross-reference: the complete consumer pattern lives in the `api-testing` skill (Phase 6, "Pattern: `for...of` with spread-and-override").

## Phase 4 consumption snippets (Tier 2 + Tier 3)

### Tier 2 — Domain-specific static data (Shape B)

```typescript
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
    test(
        `should show error for ${description}`,
        { tag: '@regression' },
        async ({ appPage }) => {
            await appPage.login(email, password);
            await expect(appPage.errorMessage).toBeVisible();
        }
    );
}
```

### Tier 3 — Field-specific boundary (inline in the spec)

```typescript
const outOfRangeRatings = [-1, 0, 0.99, 5.01, 6, 1000];

for (const invalidValue of outOfRangeRatings) {
    test(
        `should return 400 when rating is out of range (${invalidValue})`,
        { tag: '@api' },
        async ({ apiRequest }) => {
            // ...
        }
    );
}
```
