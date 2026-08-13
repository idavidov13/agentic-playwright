/**
 * auth.setup.ts
 * Playwright setup script to generate storage states for authentication.
 *
 * This runs before the main test suite to:
 * 1. Authenticate via API and store access tokens
 * 2. Generate browser storage state with session cookies
 */

import * as fs from 'node:fs';
import { expect, test } from '../../fixtures/pom/test-options';
import { StorageStatePaths } from '../../enums/app/app';
import {
    createAppStorageState,
    setUserAccessToken,
} from '../../helpers/app/createStorageState';

test.describe('auth setup', () => {
    test('setup authentication - API token', async ({ apiRequest }) => {
        await setUserAccessToken(apiRequest);
        expect(process.env['ACCESS_TOKEN']).toBeDefined();
    });

    test('setup authentication - browser storage state', async () => {
        await createAppStorageState();
        expect(fs.existsSync(StorageStatePaths.APP)).toBe(true);
    });
});
