# Data Strategy — Troubleshooting

## Parallel tests collide on email / username / ID

**Cause:** Tests share the same static value.
**Fix:** Replace with a factory (`generateUser()`, `generateLoginCredentials()`). Every test run gets a unique value.

## Factory output throws at `Schema.parse(...)`

**Cause:** The Faker defaults don't satisfy the Zod schema (missing field, wrong format, out-of-range number).
**Fix:** Update the factory defaults to match the schema. Do **not** loosen the schema to accommodate the factory — the schema is the contract (see `api-testing` Phase 1 and 7).

## I'm about to write `[123, true, null, undefined]` inline

**Fix:** Stop. Import from `test-data/static/util/invalid-values.ts` (`INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, etc.). Only field-specific boundary arrays may stay inline (Tier 3).

## I'm about to Faker-generate an error message / button label / page title

**Fix:** Stop. App-defined strings live in `enums/{area}/*`. Faker is only for user-supplied content and test-owned identifiers.

## I'm about to put a single expected string into a JSON file

**Fix:** If it's used in exactly one assertion, inline it in the test. Static TS files (`as const` exports) are for parametrised loops over curated sets, not for single values.

## I need to change a value in an existing static-data file

**Fix:** Stop. Read the `refactor-values` skill first — it owns the impact-analysis and cascading-update workflow so assertions and data-driven loops don't silently break.

## I want to centralise a timeout like `waitForTimeout(5000)`

**Fix:** Remove the hard wait entirely — use a web-first assertion (`await expect(locator).toBeVisible()`). If a genuine per-assertion override is required, pass `{ timeout }` inline on the assertion and comment why. Global timeouts belong in `playwright.config.ts` (see the `config` skill).
