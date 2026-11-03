# Destructive tests

## What counts as shared state

A test is `@destructive` only when it mutates state that lives outside the test and that other tests, users or sessions depend on:

- locale, language or region
- permissions, roles, guest access
- feature flags, global settings or configuration
- shared seed data every test reads (deleting all users, resetting a catalog)

Not destructive: a test that creates its own record, asserts on it and deletes only that record. It keeps its importance tag and runs in the parallel suite. It still needs the cleanup hook.

## Cleanup pattern

```typescript
import { ApiEndpoints } from '../../../enums/app/app';
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('admin data management', () => {
    test.afterEach(async ({ apiRequest }) => {
        // RESET_DATA is illustrative; use the reset endpoint your app provides
        await apiRequest({
            method: 'POST',
            url: ApiEndpoints.RESET_DATA,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    });

    test(
        'should delete all inactive users',
        { tag: '@destructive' },
        async ({ apiRequest }) => {
            const { status } = await apiRequest({
                method: 'DELETE',
                url: ApiEndpoints.INACTIVE_USERS,
                baseUrl: process.env.API_URL,
                headers: process.env.ACCESS_TOKEN,
            });
            expect(status).toBe(204);
        }
    );
});
```

The hook also runs after a failed test, so it must succeed when the test wrote nothing.

## Running

- `npm test` excludes `@destructive` (`--grep-invert @destructive`).
- `npm run test:destructive` runs only `@destructive` tests with `--workers=1`.

## Suite-only failures

| Symptom                          | Cause                                                                                                    | Fix                                                                                                                                        |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Passes alone, fails in the suite | Shared mutable state, a login flow without `resetStorageState`, or two tests writing the same fixed data | Per-test data from a factory; `resetStorageState` in `beforeEach`; if the test mutates shared state, retag `@destructive` and add the hook |
| State leaks between runs         | Missing or non-idempotent `afterEach` / `afterAll`                                                       | Add the hook inside the `describe`; make it succeed after a failed test                                                                    |
