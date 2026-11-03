# API schema templates

Prompt templates for Zod response schemas. `api-testing` owns contract sourcing, `type-safety` the Zod shape. Resolve `{area}` with `ls fixtures/api/schemas/` first.

## Create a schema from the documentation (default)

```
Create a Zod schema for the [STATUS] response of [ENDPOINT] from the OpenAPI document at [LOCATION].

Location fixtures/api/schemas/{area}/[name]Schema.ts (run `ls fixtures/api/schemas/` first); pattern file fixtures/api/schemas/app/userSchema.ts. Mirror the documented contract exactly (field types, required and optional, nullability, nested shapes, the envelope) per the type-safety skill; export the schema and its inferred type. A runtime response that disagrees is a bug to report, never a reason to loosen the schema (api-testing skill).
```

## Create a schema without documentation (fallback)

Only when no OpenAPI or Swagger document exists for the endpoint.

```
No documentation exists for [ENDPOINT]. Capture the observed contract by calling [API_URL/endpoint] and record the response structure, field types, optional versus required fields, nested shapes and the error bodies.

Generate fixtures/api/schemas/{area}/[name]Schema.ts from the observations per the type-safety skill, and flag the missing documentation to the team.
```

## Add fields to an existing schema

```
Add to [SCHEMA_NAME]:
- [field1]: [type and validation]
- [field2]: [type and validation]

Keep the schema strict and the type export in sync, per the type-safety skill.
```
