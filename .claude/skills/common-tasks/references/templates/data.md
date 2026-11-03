# Data templates

Prompt templates for Faker factories and static test data. `data-strategy` owns the tiers and the factory shape, `type-safety` the schema a factory parses against. Resolve `{area}` with `ls test-data/factories/` or `ls test-data/static/` first.

## Create a data factory

```
Create a factory for [DATA TYPE] at test-data/factories/{area}/[name].factory.ts (run `ls test-data/factories/` first).

Fields:
- [field1]: [faker method]
- [field2]: [faker method]

Validate the output with the matching schema from fixtures/api/schemas/{area}/ and accept overrides; pattern file test-data/factories/app/user.factory.ts. Follow the data-strategy skill.
```

## Add static test data

Pick the tier first per `data-strategy`; universal type-mismatch arrays already live in `test-data/static/util/invalid-values.ts` and are imported, never redefined.

```
Create static test data for [PURPOSE] at test-data/static/{area}/[name].ts (run `ls test-data/static/` first):
- cases: [description, value, expected outcome]

Literal values only, exported as const, per the data-strategy skill.
```
