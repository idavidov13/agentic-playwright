import * as fs from 'node:fs';
import * as path from 'node:path';
import { chromium, expect } from '@playwright/test';
import { ApiEndpoints, StorageStatePaths } from '../../enums/app/app';
import { AppPage } from '../../pages/app/app.page';
import { ApiRequestFn } from '../../fixtures/api/api-types';
import {
    UserResponse,
    UserResponseSchema,
} from '../../fixtures/api/schemas/app/userSchema';

/**
 * Creates and saves the browser storage state after successful login.
 * This is used for authentication setup before running tests.
 *
 * The storage state includes cookies and localStorage, allowing subsequent
 * tests to start in an authenticated state without performing login.
 *
 * @returns {Promise<void>} Resolves when storage state is saved.
 *
 * @example
 * ```ts
 * // In auth.setup.ts
 * test('Setup authentication', async () => {
 *   await createAppStorageState();
 * });
 * ```
 */
export async function createAppStorageState(): Promise<void> {
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();
    const appPage = new AppPage(page);

    await appPage.openLoginPage();
    await appPage.loginAndVerify(
        process.env.APP_EMAIL!,
        process.env.APP_PASSWORD!
    );

    await context.storageState({ path: StorageStatePaths.APP });
    await browser.close();
}

/**
 * Authenticates via API and saves the validated login response to
 * `StorageStatePaths.API_ACCESS_TOKEN`, so every worker process can load
 * the token with `loadUserAccessToken()`.
 *
 * Playwright runs each project in its own worker processes, and a
 * `process.env` write is visible only inside the process that made it.
 * The file is what crosses the worker boundary; `process.env.ACCESS_TOKEN`
 * is also set here for code running in the setup worker itself.
 *
 * @param {ApiRequestFn} apiRequest - The API request function from fixtures.
 * @returns {Promise<void>} Resolves when the token file is written.
 *
 * @example
 * ```ts
 * // In auth-api.setup.ts
 * test('Setup API authentication', async ({ apiRequest }) => {
 *   await setUserAccessToken(apiRequest);
 * });
 *
 * // In API tests (the token is loaded per worker by the apiRequest fixture file)
 * const { status, body } = await apiRequest<UserData>({
 *   method: 'GET',
 *   url: ApiEndpoints.CURRENT_USER,
 *   baseUrl: process.env.API_URL,
 *   headers: process.env.ACCESS_TOKEN,
 * });
 * ```
 */
export async function setUserAccessToken(
    apiRequest: ApiRequestFn
): Promise<void> {
    const { status, body } = await apiRequest<UserResponse>({
        method: 'POST',
        url: ApiEndpoints.LOGIN,
        baseUrl: process.env.API_URL,
        body: {
            email: process.env.APP_EMAIL,
            password: process.env.APP_PASSWORD,
        },
    });

    expect(status).toBe(200);
    expect(UserResponseSchema.parse(body)).toBeTruthy();

    fs.mkdirSync(path.dirname(StorageStatePaths.API_ACCESS_TOKEN), {
        recursive: true,
    });
    fs.writeFileSync(
        StorageStatePaths.API_ACCESS_TOKEN,
        JSON.stringify(body, null, 2)
    );

    process.env['ACCESS_TOKEN'] = body.access_token;
}

/**
 * Loads the access token saved by `setUserAccessToken()` into
 * `process.env.ACCESS_TOKEN` for the current worker process.
 *
 * Called automatically once per worker by the `apiRequest` fixture file.
 * A missing file is not an error: the `setup-api` project itself, or a run that
 * never minted a token, simply leaves `process.env.ACCESS_TOKEN` unset.
 *
 * @returns {void}
 */
export function loadUserAccessToken(): void {
    if (!fs.existsSync(StorageStatePaths.API_ACCESS_TOKEN)) return;

    const raw: unknown = JSON.parse(
        fs.readFileSync(StorageStatePaths.API_ACCESS_TOKEN, 'utf-8')
    );
    const { access_token } = UserResponseSchema.parse(raw);

    process.env['ACCESS_TOKEN'] = access_token;
}
