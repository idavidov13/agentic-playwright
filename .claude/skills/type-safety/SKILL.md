---
name: type-safety
description: Use when creating or extending a Zod schema under fixtures/api/schemas/**, inferring a type from a schema, annotating a function signature, removing an `any` or a cast, or choosing `!` versus `??` on a `process.env` read. Not for env-variable declarations (see `config`) or spec-side consumption (see `api-testing`).
---

# Type Safety

## Critical

- **NEVER** use `any`, `@ts-ignore` or `@ts-expect-error`: `unknown` at a boundary (network, file, user input), then `Schema.parse(...)`; a Zod-inferred type everywhere else.
- Never `as T` or `as unknown as T` to cross a type boundary; parse instead.

    ```typescript
    // CORRECT
    const raw: unknown = await response.json();
    const user = UserResponseSchema.parse(raw);
    // WRONG
    const user = (await response.json()) as UserResponse;
    ```

- Every API schema is `z.strictObject()`; `z.object()` strips unknown keys and hides contract drift.

    ```typescript
    // CORRECT
    export const UserSchema = z.strictObject({ id: z.uuid() });
    // WRONG
    export const UserSchema = z.object({ id: z.uuid() });
    ```

- Import from `zod/v4`; top-level validators (`z.uuid()`, `z.email()`, `z.url()`, `z.int()`, `z.enum(E)`), not the chained `z.string().uuid()` forms; types via `zOutput<typeof Schema>`, not `z.infer`.
- A schema mirrors the documented contract field by field, envelope included, one per endpoint response, never a factory that builds envelopes. A shared per-domain `_envelope.ts` only once the same envelope appears in 3+ schemas (canonical threshold; other skills point here).
- Export the type next to the schema: `export type User = zOutput<typeof UserSchema>;`. `zInput` only where a `.default()` or `.transform()` makes the pre-parse shape differ.
- Explicit parameter and return types on every exported or public function (`Promise<void>`, `Locator`, `string`); `npm run lint` fails without them.
- Resolve `process.env.X` where it is read: `process.env.X!` when `env/.env.example` declares it as required, `process.env.X ?? fallback` when a default is safe. Never export or pass on a `string | undefined`.

## Procedure

1. `ls fixtures/api/schemas/` resolves `{area}`; the file is `fixtures/api/schemas/{area}/<name>Schema.ts`; shared error bodies stay in `fixtures/api/schemas/util/errorResponseSchema.ts`.
2. Write the schema from the contract that `api-testing` step 1 sourced, one validator per field from `references/zod-usage.md`, the contract source in a comment at the top.
3. Export the type; `references/zod-usage.md` decides `zInput` versus `zOutput` and when to extract an envelope.
4. Hand it to the consumer: a spec asserts `expect(SchemaName.parse(body)).toBeTruthy();` (`api-testing`); a factory returns `Schema.parse(merged)` (`data-strategy`); fixture code binds `const x = Schema.parse(body);`.
5. Run `npx tsc --noEmit` and `npm run lint`. A `ZodError` against a documented contract is a bug handled per `api-testing`, never by loosening the schema.

## References

- `references/zod-usage.md`: the validator per data type, Zod 4 idioms versus project conventions, `zInput` versus `zOutput`, envelope extraction.
