---
name: data-strategy
description: Use when creating or extending a data factory, adding a static set of invalid or boundary values, or deciding whether a test value is generated, static, inline or an enum. Not for editing an existing static value (see `refactor-values`) or the loop that consumes a set (see `test-standards`).
---

# Data Strategy

## Critical

- Every file under `test-data/static/**` is `.ts` exporting `as const` literal values: never `.json`, no runtime import, no function, no computed value, no Faker call (the Constitution checks reject anything else).

    ```typescript
    // CORRECT
    export const INVALID_EMAILS = ['', 'plaintext', 'missing@domain'] as const;
    // WRONG
    export const INVALID_EMAILS = [faker.internet.email(), buildBadEmail()];
    ```

- Never hardcode test content strings (names, emails, descriptions, product names) in a spec or page object; generate them with a Faker factory from `test-data/factories/{area}/`.

    ```typescript
    // CORRECT
    const product = generateProduct();
    // WRONG
    const product = { name: 'Test Product 1', price: 9.99 };
    ```

- Never redefine the universal type-mismatch arrays inline; import `INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, `INVALID_BOOLEAN_VALUES`, `INVALID_UUID_VALUES`, `INVALID_ENUM_VALUES`, `INVALID_ARRAY_VALUES` and `INVALID_OBJECT_VALUES` from `test-data/static/util/invalid-values.ts`.
- A factory merges `overrides` over Faker defaults, returns `Schema.parse(merged)` and carries the Zod-inferred return type; never a cast.
- Never Faker-generate an app-defined string (error message, label, heading, route); those come from `enums/{area}/*` (`enums`).
- A value used in exactly one assertion stays inline in the test; a static file holds a curated set that a loop iterates.
- Editing an existing static value or enum member goes through `refactor-values` first.
- No magic numbers inline (timeouts, retry counts, limits): suite tuning in `playwright.config.ts` (`config`), domain limits in `enums/{area}/*`, a per-assertion `{ timeout }` only with a comment saying why.

## Procedure

1. Classify the value; `ls test-data/static/` and `ls test-data/factories/` resolve `{area}`. App-defined strings go to `enums`, tuning numbers to `config`; anything that fits no row: stop and ask.

    | Value                                                        | Home                                                      |
    | ------------------------------------------------------------ | --------------------------------------------------------- |
    | Happy-path dynamic data (names, emails, ids, content)        | factory in `test-data/factories/{area}/<name>.factory.ts` |
    | Universal type-mismatch values                               | import from `test-data/static/util/invalid-values.ts`     |
    | Curated invalid or boundary set tied to the app's validation | `test-data/static/{area}/<name>.ts`                       |
    | Range violation for one field, used in one spec              | inline array in the spec                                  |

2. Factory: the schema must exist in `fixtures/api/schemas/{area}/` (`type-safety`); write it per `references/factories.md`.
3. Static set: pick the tier and the file shape per `references/static-data-tiers.md`; a set a second spec or field needs moves from inline to `test-data/static/{area}/`.
4. Consume: the factory call in the spec, fixture or page-object action; a static export through a `for...of` loop per `test-standards`. Run `npm run lint` and the affected tests.

## References

- `references/factories.md`: open when creating or extending a factory, pinning fields with overrides, or when `Schema.parse` throws inside one.
- `references/static-data-tiers.md`: open when adding a static set: the three tiers, the two file shapes, promotion from inline, collisions between parallel tests.
