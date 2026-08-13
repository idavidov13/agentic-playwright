import type { Locator } from '@playwright/test';
import { expect, test } from '../../../fixtures/pom/test-options';
import { AppPage } from '../../../pages/app/app.page';
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

/** Maps an expected-error kind from the static data to its page-object locator. */
const errorLocator = (
    appPage: AppPage,
    kind: (typeof INVALID_LOGIN_ATTEMPTS)[number]['expectedErrors'][number]
): Locator => {
    switch (kind) {
        case 'invalid-credentials':
            return appPage.errorMessage;
        case 'email-format':
            return appPage.emailFormatError;
        case 'email-required':
            return appPage.emailRequiredError;
        case 'password-required':
            return appPage.passwordRequiredError;
    }
};

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

    for (const {
        description,
        email,
        password,
        expectedErrors,
    } of INVALID_LOGIN_ATTEMPTS) {
        test(
            `should show error for invalid credentials - ${description}`,
            { tag: '@regression' },
            async ({ appPage }) => {
                await test.step(`WHEN user enters invalid credentials - email: ${email}`, async () => {
                    await appPage.login(email, password);
                });

                await test.step('THEN the expected error messages should be displayed', async () => {
                    for (const kind of expectedErrors) {
                        await expect(errorLocator(appPage, kind)).toBeVisible();
                    }
                });
            }
        );
    }
});
