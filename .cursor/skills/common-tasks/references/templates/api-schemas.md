# API Schema Templates

Prompt templates for Zod response schemas. The `api-testing` (Phase 1) and `type-safety` skills own the deep rules. Resolve `{area}` with `ls fixtures/api/schemas/` first.

> **Important:** Source schemas from OpenAPI / Swagger documentation when it exists. Only capture the live response shape as a fallback for undocumented endpoints. See the `api-testing` skill (Phase 1).

## Create a New Zod Schema (From Documentation — Default)

```
Create a Zod schema for [ENDPOINT] based on the OpenAPI / Swagger documentation.

First, run `ls fixtures/api/schemas/` to find the correct area subdirectory.

Then generate the schema from the documented contract:
- Location: fixtures/api/schemas/{area}/[name]Schema.ts  (use real area name from ls)
- Use z.strictObject() — never z.object()
- Field types, required/optional, nullability, and nested shapes exactly match the spec
- Proper Zod validators (z.email(), z.uuid(), z.url(), z.int(), etc.)
- Export both the schema and the inferred TypeScript type
- Spell out the response envelope (success / message / data / errors) as a z.strictObject per the OpenAPI spec — schemas are a 1:1 mirror of the documented contract; do not invent a factory helper. If the envelope repeats across 3+ endpoints in one domain, extract `fixtures/api/schemas/{area}/_envelope.ts` and compose via .extend(...)
- Follow the pattern from fixtures/api/schemas/app/userSchema.ts

If a runtime response disagrees with the schema later, that is a bug —
report it and wrap the test with test.skip + // FIXME: <ticket-url>.
Do NOT loosen the schema to match buggy behavior.
```

## Create a New Zod Schema (Fallback — No Documentation Available)

Use this only when no OpenAPI / Swagger documentation exists for the endpoint.

```
Create a Zod schema for [ENDPOINT]. No documentation exists for this endpoint,
so we are capturing the observed contract.

First, run `ls fixtures/api/schemas/` to find the correct area subdirectory.

Then make a request to [API_URL/endpoint] to discover:
- Actual response structure and field names
- Data types for each field
- Optional vs required fields
- Nested objects or arrays
- Error response formats

Then generate the schema with:
- Location: fixtures/api/schemas/{area}/[name]Schema.ts  (use real area name from ls)
- Use z.strictObject() — never z.object()
- Accurate field types based on the actual response
- Proper Zod validators (z.email(), z.uuid(), z.url(), z.int(), etc.)
- Exported TypeScript type
- Flag missing documentation to the team as a follow-up
```

## Add Fields to Existing Schema

```
Add the following fields to [SCHEMA_NAME]:
- [field1]: [type with validation rules]
- [field2]: [type with validation rules]

Update the corresponding TypeScript type export.
Keep z.strictObject(); do not weaken to z.object().
```
