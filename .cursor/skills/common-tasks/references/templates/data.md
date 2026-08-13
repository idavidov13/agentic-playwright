# Data Templates

Prompt templates for dynamic Faker factories and curated static test data. The `data-strategy` and `type-safety` skills own the deep rules. Resolve `{area}` with `ls test-data/factories/` or `ls test-data/static/` first.

## Create a New Data Factory

```
Create a data factory for [DATA TYPE]:
- Location: test-data/factories/{area}/[name].factory.ts  (run `ls test-data/factories/` first)
- Use @faker-js/faker for data generation
- Validate output with Zod schema from fixtures/api/schemas/
- Support overrides parameter for customization
- Support seed option for reproducibility

Fields to generate:
- [field1]: [faker method to use]
- [field2]: [faker method to use]
```

## Add Static Test Data

Before adding static data, pick the right tier per the three-tier rule (see the `api-testing` skill, Phase 6, and the `data-strategy` skill):

1. **Universal type-mismatch arrays** (wrong type for any field of a given primitive type) → already centralised in `test-data/static/util/invalid-values.ts`. Import from there; do not create new ones.
2. **Domain-specific curated invalid values** (invalid email formats, password policy violations, invalid locales, forbidden enum values, etc.) → live under `test-data/static/{area}/` — this is the tier a new static file usually belongs to.
3. **Field-specific boundary / range values** (e.g., out-of-range for a `1..5` number) → may stay inline in the spec when used in exactly one place.

Static data files are TypeScript only (`.ts` with `as const` exports). Never `.json`. The file may export only literal values — no runtime imports, no functions, no Faker.

```
Create static test data for [PURPOSE] at the correct tier:
- Tier: [domain-specific → test-data/static/{area}/ | universal type-mismatch → already in test-data/static/util/invalid-values.ts]
- Location: test-data/static/{area}/[name].ts  (run `ls test-data/static/` first)
- Use for: [domain-specific invalid values | boundary testing | edge cases]

Data structure (as const literal values only, no logic):

export const [CATEGORY] = [
    { description: '', value: '' },
] as const;
```
