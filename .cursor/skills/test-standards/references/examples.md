# Test Standards — Worked Examples

Four end-to-end spec patterns, one per test type the scaffold supports. Phase numbers refer to `test-standards/SKILL.md`.

## Example 1: Functional smoke test

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('login', () => {
    test.beforeEach(async ({ resetStorageState, appPage }) => {
        await resetStorageState();
        await appPage.openHomePage();
    });

    test(
        'should login successfully with valid credentials',
        { tag: '@smoke' },
        async ({ appPage }) => {
            await test.step('WHEN user enters valid credentials', async () => {
                await appPage.login(
                    process.env.APP_EMAIL!,
                    process.env.APP_PASSWORD!
                );
            });

            await test.step('THEN user should see username displayed', async () => {
                await expect(appPage.username).toBeVisible();
            });
        }
    );
});
```

## Example 2: Data-driven regression (TS static data)

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

test.describe('login - invalid credentials', () => {
    test.beforeEach(async ({ resetStorageState, appPage }) => {
        await resetStorageState();
        await appPage.openHomePage();
    });

    for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
        test(
            `should show error for ${description}`,
            { tag: '@regression' },
            async ({ appPage }) => {
                await appPage.login(email, password);
                await expect(appPage.errorMessage).toBeVisible();
            }
        );
    }
});
```

## Example 3: Destructive test with cleanup

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';
import { ApiEndpoints } from '../../../enums/app/app';

test.describe('admin - data management', () => {
    test.afterEach(async ({ apiRequest }) => {
        await apiRequest({
            method: 'POST',
            url: ApiEndpoints.RESET_DATA, // illustrative
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
                url: '/api/admin/inactive-users',
                baseUrl: process.env.API_URL,
                headers: process.env.ACCESS_TOKEN,
            });

            expect(status).toBe(204);
        }
    );
});
```

Run with: `npm run test:destructive` (single worker, excluded from `npm test`).

## Example 4: E2E multi-feature journey

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('todo - full journey', () => {
    test.beforeEach(async ({ resetStorageState, appPage }) => {
        await resetStorageState();
        await appPage.openHomePage();
    });

    test(
        'should add, complete, filter, clear, and verify final state',
        { tag: '@e2e' },
        async ({ todoPage }) => {
            await test.step('GIVEN user creates three todos', async () => {
                await todoPage.addTodo('Buy milk');
                await todoPage.addTodo('Walk dog');
                await todoPage.addTodo('Read book');
                await expect(todoPage.todoItems).toHaveCount(3);
            });

            await test.step('WHEN user completes one and filters to active', async () => {
                await todoPage.completeTodo('Buy milk');
                await todoPage.filterByActive();
            });

            await test.step('THEN only the two active todos remain visible', async () => {
                await expect(todoPage.todoItems).toHaveCount(2);
            });

            await test.step('WHEN user clears completed', async () => {
                await todoPage.clearCompleted();
            });

            await test.step('THEN completed count is zero', async () => {
                await expect(todoPage.completedCount).toHaveText('0');
            });
        }
    );
});
```
