# Examples — Multi-Skill Chains

Three end-to-end walkthroughs showing how the 8-phase workflow chains across specialized skills.

## Example 1: "Add tests for a new endpoint"

User: _"Add API tests for `POST /api/products`."_

1. **Phase 1 — Classify** — Codegen, API test.
2. **Phase 2 — Route** — `common-tasks` (template) → `api-testing` (deep rules).
3. **Phase 3 — Explore** — Confirm OpenAPI exists for `/api/products`; if not, fall back to `apiRequest` exploration. `ls fixtures/api/schemas/`, `ls tests/`, `ls enums/`.
4. **Phase 4 — Plan + Confidence** — Schema name + location, factory name + location, spec file structure, coverage plan covering every status code from the OpenAPI block, validation tiers (universal `INVALID_*` + per-field omission + path-param fuzzing). Output confidence + unknowns.
5. **Phase 5 — Human gate** — Confirm scope.
6. **Phase 6 — Apply** — `z.strictObject` (`type-safety`), `expect(Schema.parse(body)).toBeTruthy();` (`api-testing` / `type-safety`), `ApiEndpoints.PRODUCTS` (`enums`), Faker factory (`data-strategy`), single-tag `@api` (`test-standards`).
7. **Phase 7 — Verify** — Run `npx playwright test tests/{area}/api/products.spec.ts` against the `api-testing` Phase 5 coverage matrix and the `common-tasks` verification checklist. On red, load `debugging`.
8. **Phase 8 — Report + commit** — _"Add POST /api/products tests with full coverage matrix"_.

## Example 2: "Rename an enum value safely"

User: _"Backend renamed `/api/users/login` to `/api/auth/login`. Update us."_

1. **Phase 1 — Classify** — Refactor.
2. **Phase 2 — Route** — `refactor-values` direct.
3. **Phase 3 — Explore** — `rg "ApiEndpoints.LOGIN" .` and `rg "'/api/users/login'" .` to find every consumer.
4. **Phase 4 — Plan + Confidence** — `enums/{area}/app.ts` change + impacted spec files + helpers + sibling skill docs that mention the old path. Confidence + unknowns.
5. **Phase 5 — Human gate** — Confirm.
6. **Phase 6 — Apply** — Follow `refactor-values` end-to-end (impact tables, atomic edit, no schema loosening).
7. **Phase 7 — Verify** — `npx tsc --noEmit` + `npx eslint .` + `npx playwright test --grep "login"`. On red, if backend isn't deployed yet, follow `api-testing` Phase 7 (`test.skip` + `// FIXME:`).
8. **Phase 8 — Report + commit** — _"Rename ApiEndpoints.LOGIN to /api/auth/login per backend change"_.

## Example 3: "CI red, local green"

User: _"My PR's CI is failing on `tests/app/functional/login.spec.ts` but it passes locally every time."_

1. **Phase 1 — Classify** — Debug.
2. **Phase 2 — Route** — `debugging` direct.
3. **Phase 3 — Explore** — `gh run download <id> -n playwright-report`; `npx playwright show-trace path/to/trace.zip`.
4. **Phase 4 — Plan + Confidence** — Often skipped for focused investigation, but still output a confidence on root-cause hypothesis before committing a fix.
5. **Phase 5 — Human gate** — Confirm hypothesis.
6. **Phase 6 — Apply** — Follow `debugging` Phase 7 (CI-only failure replay): compare envs (`ENVIRONMENT`, viewport, browser version), check `auth.setup.ts` produced storage state, replay locally with `ENVIRONMENT=ci CI=1`. Diagnose root cause (e.g. `auth.setup.ts` raced an unwarmed app container). Fix at root cause (readiness probe in setup).
7. **Phase 7 — Verify** — Push, watch CI through 5+ consecutive green runs.
8. **Phase 8 — Report + commit** — _"Wait for app readiness in auth.setup.ts to fix CI race"_.
