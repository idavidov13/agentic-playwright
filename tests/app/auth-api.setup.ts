/**
 * auth-api.setup.ts
 * Playwright setup script for the API access token (`setup-api` project).
 *
 * Signs in over HTTP only, so the `api` project never needs a browser or
 * the UI storage state: it passes on fresh environments and in CI where the
 * UI may be unreachable. The browser storage state is `auth.setup.ts`.
 */

import { expect, test } from '../../fixtures/pom/test-options';
import { setUserAccessToken } from '../../helpers/app/createStorageState';

test.describe('auth setup - API', () => {
    test('setup authentication - API token', async ({ apiRequest }) => {
        await setUserAccessToken(apiRequest);
        expect(process.env['ACCESS_TOKEN']).toBeDefined();
    });
});
