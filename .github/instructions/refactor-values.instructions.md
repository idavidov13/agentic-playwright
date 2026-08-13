---
applyTo: 'enums/**/*.ts,test-data/static/**/*.ts'
---

# Refactoring Enum Values and Static Test Data

## Critical

- **ALWAYS** run Phase 1 (find all consumers) before making any edit. Enum values and static data feed into tests, page objects, schemas, and assertions — the blast radius must be known up front.
- **ALWAYS** search for both the **enum key** (`Messages.LOGIN_ERROR`) **and the raw string value** (`'Invalid email or password'`). Some consumers may have bypassed the enum and hardcoded the string — they won't update when you change the enum.
- **NEVER** update an enum value, rename a key, or edit a static-data file without updating every consumer **in the same commit** (atomicity — no intermediate broken state).
- **NEVER** loosen a Zod schema (`z.literal` / `z.enum`) to make an updated value pass. Update the schema to match the new value; the schema is the contract.
- **ALWAYS** run `npx tsc --noEmit` + `npx eslint .` + the affected tests before concluding the refactor. TypeScript catches key renames; eslint catches stale patterns; tests catch assertion drift.
- **NEVER** use a single global find-and-replace — it misses case variants, hardcoded copies, and references inside comments, documentation, and sibling skill files. Inspect each match.

## Instructions

### Phase 1: Find all consumers before touching anything

Search the **entire codebase** for every occurrence of both:

1. The **enum key** (the import reference consumers use).
2. The **current string value** (the raw string — catches hardcoded usages that bypass the enum).

Use `rg` (ripgrep) when available — faster and more ergonomic — or `grep -r` as a universal fallback:

```bash
# Find all usages of the enum key
rg "Messages.LOGIN_ERROR" .
grep -r "Messages.LOGIN_ERROR" .

# Find all usages of the raw string value
rg "Invalid email or password" .
grep -r "Invalid email or password" .

# For endpoint changes, search both
rg "ApiEndpoints.LOGIN" .
rg "'/api/users/login'" .
```

> Do this before making any edits. Understand the full blast radius first. Expect matches in `.ts`, `.tsx`, `.md` (instruction files, README, CHANGELOG), and `.json` (Playwright reports — ignore).

### Phase 2: Categorize impact using the right table

Pick the table that matches the change you are making.

**For enum string-value changes** (changing what the member resolves to):

| Consumer Type                                                                 | What to Check          | Action Required                                   |
| ----------------------------------------------------------------------------- | ---------------------- | ------------------------------------------------- |
| Tests with `toHaveText()` / `toBeVisible()` using the old raw value           | Will fail if hardcoded | Update to use enum or new value                   |
| Page object locators using `getByText(Messages.X)`                            | Auto-updated via enum  | No change needed — enum reference already correct |
| Zod schemas with `z.literal('old-value')` or `z.enum([..., 'old-value'])`     | Will reject new value  | Update literal/enum to new value                  |
| API endpoint paths in `apiRequest` calls                                      | Will call wrong URL    | Update enum reference or hardcoded path           |
| Static data in `test-data/static/*.ts` using the old string as expected value | Test data mismatch     | Update the `as const` entry                       |
| Other enum members that derive from this value                                | Indirect breakage      | Audit and update                                  |

**For enum key renames** (e.g., `LOGIN_ERROR` → `AUTH_FAILURE`):

| Consumer Type                                         | What to Check                | Action Required                    |
| ----------------------------------------------------- | ---------------------------- | ---------------------------------- |
| Every file importing and using the old key            | TypeScript compile error     | Rename key reference in every file |
| Re-exports or barrel files                            | May silently pass at runtime | Check `index.ts` files             |
| Documentation / skill files referring to the old name | Reader confusion             | Update `.md` files too             |

**For static data value changes** (editing a file in `test-data/static/*.ts`):

| Consumer Type                                                   | What to Check                             | Action Required                             |
| --------------------------------------------------------------- | ----------------------------------------- | ------------------------------------------- |
| Tests importing the named `as const` export and looping over it | May use the changed value in an assertion | Verify test assertions still match new data |
| Tests asserting against a specific value from the file directly | Will fail                                 | Update hardcoded expected value in the test |
| Enum members mirroring the static-data string                   | Out of sync                               | Update the matching enum member             |

### Phase 3: Make all changes atomically

Update the source (enum or static-data file) **and all consumers in one pass**. Never leave an intermediate broken state where the value is changed but consumers still reference the old value.

Recommended order:

1. Change the enum value / rename the key / update the `as const` entry in the static-data file.
2. Update every consumer identified in Phase 1.
3. Run TypeScript compile check.
4. Lint.
5. Run affected tests.

### Phase 4: Verify no breakage

```bash
# 1. TypeScript -- catches key renames and type mismatches
npx tsc --noEmit

# 2. Lint
npx eslint .

# 3. Run tests that use the changed value (adjust grep pattern)
npx playwright test --grep "@api"
```

Notes on `npx playwright test --grep`:

- Matches against **tag names** (`@smoke`, `@api`, etc.) and against **test titles**. Use the most specific filter.
- If the change touches a single spec file, run that file directly instead of `--grep`.

If any test fails, trace the failure back to a missed consumer from Phase 1 and update it.

## Anti-Patterns

```typescript
// ANTI-PATTERN 1 -- string value changed but test still hardcodes old value
export enum Messages {
    LOGIN_ERROR = 'Incorrect credentials. Please try again.', // updated
}

// This test now fails silently -- old string no longer matches the UI:
await expect(page.getByText('Invalid email or password')).toBeVisible(); // STALE
```

```typescript
// ANTI-PATTERN 2 -- enum key renamed but not all usages updated
// File A: updated ✅
Messages.AUTH_FAILURE;

// File B: still using old key -- TypeScript error (caught by tsc --noEmit)
Messages.LOGIN_ERROR; // ❌ Property 'LOGIN_ERROR' does not exist
```

```typescript
// ANTI-PATTERN 3 -- static data changed but assertion not updated
// test-data/static/app/invalidCredentials.ts was updated with a new password
// but the test still asserts the old password is present in the response
expect(response.password).toBe('WrongPassword123!'); // ❌ stale assertion
```

```typescript
// ANTI-PATTERN 4 -- Zod schema loosened to "fix" a drift
// BEFORE
role: z.literal('admin'),

// WRONG -- hides future drift instead of tracking the contract
role: z.string(),

// CORRECT -- update the literal to the new value (or switch to z.enum([...])
// if multiple values are valid)
role: z.literal('administrator'),
```

## See Also

- **`enums`** skill — enum conventions, organization, and how to define NEW enums (this skill covers CHANGING existing ones).
- **`data-strategy`** skill — static data file structure (`.ts` with `as const` exports, three-tier rule) and how to ADD new static data.
- **`test-standards`** skill — how data-driven tests import and use static TS modules.
- **`type-safety`** skill — Zod schema patterns; `z.literal()` and `z.enum()` that may reference enum values.
- **`api-testing`** skill — consumers of `ApiEndpoints.*` and how schema drift is handled via `test.skip` + `// FIXME:`.
- **`debugging`** skill — Phase 4 verification failures during a refactor (text mismatch, ZodError, strict-mode violation) — classify the failure and use the right tool before assuming the refactor itself is wrong.
