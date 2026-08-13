# Refactor-Values — Worked Examples

## Example 1: API endpoint URL changed

The backend renamed `/api/users/login` → `/api/auth/login`.

```typescript
// enums/{area}/app.ts -- BEFORE
export enum ApiEndpoints {
    LOGIN = '/api/users/login',
}

// enums/{area}/app.ts -- AFTER
export enum ApiEndpoints {
    LOGIN = '/api/auth/login',
}
```

**Required follow-up:**

- Search for `'/api/users/login'` — anyone who hardcoded it instead of using the enum must be updated.
- Search for `ApiEndpoints.LOGIN` — verify all usages are correct (no string concatenation that would silently use the old value).
- Check `fixtures/api/schemas/` for any schema using the old path as a `z.literal()`.
- Check `helpers/` and `tests/{area}/auth.setup.ts` for hardcoded endpoint strings.
- Check `README.md`, `CHANGELOG.md`, and sibling skill files (`api-testing`, `common-tasks`, `enums`) for documentation references.

## Example 2: UI error message wording changed

The UI now shows different text and the enum needs updating.

```typescript
// enums/{area}/app.ts -- BEFORE
export enum Messages {
    LOGIN_ERROR = 'Invalid email or password',
}

// enums/{area}/app.ts -- AFTER
export enum Messages {
    LOGIN_ERROR = 'Incorrect credentials. Please try again.',
}
```

**Required follow-up:**

- Search for the old string `'Invalid email or password'` — any test hardcoding it will now fail.
- Tests using `getByText(Messages.LOGIN_ERROR)` or `toHaveText(Messages.LOGIN_ERROR)` update automatically.
- Check `test-data/static/*.ts` files for the old string as an expected value field (unlikely but possible if the scaffold mirrors UI text in test cases).
- Verify the new text by running `playwright-cli` and comparing against the live app — see the `enums` skill (Phase 4).

## Example 3: Enum key renamed

```typescript
// enums/{area}/app.ts -- BEFORE
export enum Messages {
    LOGIN_ERROR = 'Invalid email or password',
}

// enums/{area}/app.ts -- AFTER
export enum Messages {
    AUTH_FAILURE = 'Invalid email or password',
}
```

**Required follow-up:**

- Every file that referenced `Messages.LOGIN_ERROR` is now a TypeScript error.
- Run `npx tsc --noEmit` to surface all locations immediately.
- Update every reference from `Messages.LOGIN_ERROR` to `Messages.AUTH_FAILURE`.
- Search for the old key as a string in comments or documentation too (`.md` files, `.cursor/rules/*`).

## Example 4: Static data value changed

Static data files are TypeScript with `as const` exports — see the `data-strategy` skill (Phase 3, Tier 2).

```typescript
// test-data/static/{area}/invalidCredentials.ts -- BEFORE
export const INVALID_LOGIN_ATTEMPTS = [
    {
        description: 'valid email with wrong password',
        email: 'test.user@example.com',
        password: 'WrongPassword123!',
    },
    // ...
] as const;

// test-data/static/{area}/invalidCredentials.ts -- AFTER
export const INVALID_LOGIN_ATTEMPTS = [
    {
        description: 'valid email with wrong password',
        email: 'test.user@example.com',
        password: 'UpdatedWrongPassword!',
    },
    // ...
] as const;
```

**Required follow-up:**

- Find all test files that import this module:
    ```bash
    rg "from.*test-data/static/app/invalidCredentials" .
    rg "INVALID_LOGIN_ATTEMPTS" .
    ```
- For each test, check if it asserts against the old password value `'WrongPassword123!'` anywhere (hardcoded).
- Verify the test behavior is still correct with the new data (it still tests the right boundary condition).
- Check whether any enum member mirrors this value and needs updating.
