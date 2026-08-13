# Type Safety — Troubleshooting

## A breaking API change slipped through — tests pass but production fails

**Cause:** Schema used `z.object()` instead of `z.strictObject()`. Extra fields were silently stripped; missing fields were silently `undefined`.
**Fix:** Switch the schema to `z.strictObject()`. Re-run tests — the contract drift will now surface as `ZodError`.

## TypeScript says `process.env.X` is `string | undefined`

**Fix:** Apply `!` (`process.env.X!`) when the value is guaranteed at runtime, or `??` with a safe fallback (`process.env.X ?? 'default'`). Never let `string | undefined` spread into downstream code.

## I silenced a compile error with `as unknown as T`

**Cause:** The value's real shape isn't known — TypeScript can't tell, which is why you needed the cast.
**Fix:** Replace the cast with `const typed = Schema.parse(raw);`. You get runtime validation + a real type, instead of a lie.

## My inferred type has optional fields I didn't expect

**Cause:** You used `zOutput` on a schema with `.default(...)`.
**Fix:** If you want the **pre-parse** shape (where defaulted fields are optional), use `zInput<typeof Schema>` instead. Use `zOutput` for the post-parse result (which is what consumers of the parsed value see).

## `expect(Schema.parse(body)).toBeTruthy()` throws `ZodError`

**Cause:** The API response genuinely disagrees with the schema (contract drift, undocumented optional field, wrong nullability).
**Fix:** This is a real bug — follow the `api-testing` skill (Phase 7): keep the test as the spec says, wrap with `test.skip` + `// FIXME: <ticket-url>`, and report the discrepancy. Do not loosen the schema to make the error go away; see the `refactor-values` skill (Anti-Pattern 4) for why.

## I'm repeating `{ success, message, data, errors }` across multiple schemas

**Cause:** The same envelope appears across many endpoints in one domain.
**Fix:** Extract a per-domain shared envelope as a `z.strictObject` (e.g. `fixtures/api/schemas/{area}/_envelope.ts`) and compose with `.extend(...)` only when the repetition is real and observed across 3+ schemas. Do **not** create a generic envelope factory — schemas should remain a 1:1 mirror of the documented OpenAPI contract per endpoint.

## My function has implicit `any` parameters but strict mode isn't complaining

**Cause:** TypeScript might have inferred a concrete type from a contextual call — but the declaration is still wrong.
**Fix:** Add explicit parameter types. Relying on contextual inference is brittle; a future refactor will drop the context and the function silently becomes `any`-typed.
