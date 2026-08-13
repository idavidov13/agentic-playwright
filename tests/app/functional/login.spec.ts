import { expect, test } from '../../../fixtures/pom/test-options';
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

/**
 * Example functional test suite for login functionality.
 * Replace this with your actual login tests.
 */
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

            await test.step('THEN user should see username displayed', async () => {
                await expect(appPage.username).toBeVisible();
            });
        }
    );

    for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
        test(
            `should show error for invalid credentials - ${description}`,
            { tag: '@regression' },
            async ({ appPage }) => {
                await test.step(`WHEN user enters invalid credentials - email: ${email}`, async () => {
                    await appPage.login(email, password);
                });

                await test.step('THEN error message should be displayed', async () => {
                    await expect(appPage.errorMessage).toBeVisible();
                });
            }
        );
    }
});
