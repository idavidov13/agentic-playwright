# Spec patterns

Paths assume `tests/{area}/<type>/`; run `ls tests/` for the real area. The live instances are `tests/app/functional/login.spec.ts`, `tests/app/e2e/e2e.spec.ts`, `tests/app/auth.setup.ts` and `tests/app/auth-api.setup.ts`. API specs follow `api-testing`.

## Functional

One behaviour per test. The `chromium` project starts signed in through the storage state; `resetStorageState()` clears cookies, permissions and the app's web storage so the test starts signed out (a login page, a form that pre-fills the user's data).

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('functional login', () => {
    test.beforeEach(async ({ resetStorageState, appPage }) => {
        await resetStorageState();
        await appPage.openLoginPage();
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

            await test.step('THEN user sees the username', async () => {
                await expect(appPage.username).toBeVisible();
            });
        }
    );
});
```

## Data-driven

The loop sits inside `describe` and outside `test()`, so each row is its own test. Rows come from a static `.ts` file (`data-strategy`). When rows carry an expected-error kind, map it to a locator in the spec, as `tests/app/functional/login.spec.ts` does.

```typescript
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
    test(
        `should show error for invalid credentials - ${description}`,
        { tag: '@regression' },
        async ({ appPage }) => {
            await appPage.login(email, password);
            await expect(appPage.errorMessage).toBeVisible();
        }
    );
}
```

## E2E

One test for the whole journey, chained with steps. The `chromium` project loads the storage state from setup, so the test starts signed in.

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('e2e checkout', () => {
    test.beforeEach(async ({ appPage }) => {
        await appPage.openHomePage();
    });

    test(
        'should add a product and complete checkout',
        { tag: '@e2e' },
        async ({ appPage }) => {
            await test.step('GIVEN user is signed in', async () => {
                await expect(appPage.username).toBeVisible();
            });

            await test.step('WHEN user adds a product and pays', async () => {
                // chain page-object actions here
            });

            await test.step('THEN the order confirmation is shown', async () => {
                // final assertion on the journey outcome
            });
        }
    );
});
```

## Setup

`tests/{area}/*.setup.ts` runs in the `setup` project before `chromium` (`playwright.config.ts`). No tag. It mints the API token and the storage state through the helpers in `helpers/{area}/`:

```typescript
import * as fs from 'node:fs';
import { expect, test } from '../../fixtures/pom/test-options';
import { StorageStatePaths } from '../../enums/app/app';
import { createAppStorageState } from '../../helpers/app/createStorageState';

test('setup authentication - browser storage state', async () => {
    await createAppStorageState();
    expect(fs.existsSync(StorageStatePaths.APP)).toBe(true);
});
```
