# Static data tiers

Static files hold curated sets that a `for...of` loop iterates (`test-standards` has the loop skeleton). Every file is `.ts` with `as const` exports of literal values; the Constitution checks reject anything else.

## Tier 1: universal type-mismatch arrays

`test-data/static/util/invalid-values.ts` already exists; import it, never redefine or extend it inline. Seven exports: `INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, `INVALID_BOOLEAN_VALUES`, `INVALID_UUID_VALUES`, `INVALID_ENUM_VALUES`, `INVALID_ARRAY_VALUES`, `INVALID_OBJECT_VALUES`. Read the file for the values; a copy in a document goes stale.

## Tier 2: domain-specific sets in `test-data/static/{area}/`

A new file for a curated set tied to the app's validation rules (malformed emails, weak passwords, forbidden categories). The live instance is `test-data/static/app/invalidCredentials.ts`; it carries both shapes.

Shape A, one array per field, for a loop that targets one field at a time:

```typescript
export const INVALID_EMAILS = ['', 'plaintext', 'missing@domain'] as const;
export const INVALID_PASSWORDS = ['', '123', 'short'] as const;
```

Shape B, one object per scenario, for a loop that fills several fields and checks an outcome:

```typescript
export const INVALID_LOGIN_ATTEMPTS = [
    {
        description: 'valid email with wrong password',
        email: 'test.user@example.com',
        password: 'WrongPassword123!',
        expectedErrors: ['invalid-credentials'],
    },
] as const;
```

An expected outcome is a kind (`'invalid-credentials'`), not a message string: the spec maps the kind to the `Messages` enum, because a static file cannot import the enum.

Tier 1 and Tier 2 run in separate loops; a domain set is never merged into a universal array.

## Tier 3: inline boundary values

A range violation for one field, used in one spec, stays in the spec:

```typescript
const outOfRangeRatings = [-1, 0, 5.01, 1000];
```

It moves to Tier 2 when a second spec or a second field needs the same set.

## Collisions between parallel tests

Two tests failing on a duplicate email, name or id share a static value. Replace it with a factory call: a static set is for invalid inputs and expected rejections, not for data a test creates.
