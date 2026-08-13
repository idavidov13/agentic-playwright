import { defineConfig, devices } from '@playwright/test';
import dotenv from 'dotenv';
import { StorageStatePaths } from './enums/app/app';

/**
 * Load environment variables from .env file.
 * Defaults to ./env/.env.dev if ENVIRONMENT is not set.
 *
 * Usage:
 *   ENVIRONMENT=staging npx playwright test
 */
const environment = process.env.ENVIRONMENT ?? 'dev';
const environmentPath = `./env/.env.${environment}`;

// quiet: dotenv v17+ prints promotional "injected env" banners by default
dotenv.config({ path: environmentPath, quiet: true });

/**
 * Playwright Test Configuration
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
    testDir: './tests',

    /* Run tests in files in parallel */
    fullyParallel: true,

    /* Fail the build on CI if you accidentally left test.only in the source code */
    forbidOnly: !!process.env.CI,

    /* Retry on CI only */
    retries: process.env.CI ? 2 : 0,

    /* Limit parallel workers on CI for stability */
    workers: process.env.CI ? 1 : undefined,

    /* Reporter configuration */
    reporter: process.env.CI
        ? [['blob'], ['html', { open: 'never' }]]
        : [['html', { open: 'on-failure' }]],

    /* Shared settings for all projects */
    use: {
        /* Base URL - uncomment and set if using relative URLs */
        // baseURL: process.env.APP_URL,

        /* The app under test exposes test ids via data-test attributes */
        testIdAttribute: 'data-test',

        /* Collect trace when retrying the failed test */
        trace: 'on-first-retry',

        /* Screenshot on failure */
        screenshot: 'only-on-failure',

        /* Video on failure */
        video: 'retain-on-failure',

        /* Action timeout */
        actionTimeout: 10000,

        /* Navigation timeout */
        navigationTimeout: 30000,
    },

    /* Test timeout */
    timeout: 60000,

    /* Expect timeout */
    expect: {
        timeout: 10000,
    },

    /* Configure projects */
    projects: [
        /* Setup project - runs before main tests */
        {
            name: 'setup',
            use: {
                ...devices['Desktop Chrome'],
                viewport: { width: 1920, height: 1080 },
            },
            testMatch: /.*\.setup\.ts/,
        },

        /* API test project - request-context only, no browser storage state */
        {
            name: 'api',
            testMatch: /.*\/api\/.*\.spec\.ts/,
        },

        /* Main UI test project - Chrome */
        {
            name: 'chromium',
            testIgnore: /.*\/api\/.*\.spec\.ts/,
            use: {
                ...devices['Desktop Chrome'],
                storageState: StorageStatePaths.APP,
                viewport: { width: 1920, height: 1080 },
            },
            dependencies: ['setup'],
        },

        /* Firefox - commented out by default */
        // {
        //     name: 'firefox',
        //     use: {
        //         ...devices['Desktop Firefox'],
        //         storageState: '.auth/app/appStorageState.json',
        //     },
        //     dependencies: ['setup'],
        // },

        /* WebKit - commented out by default */
        // {
        //     name: 'webkit',
        //     use: {
        //         ...devices['Desktop Safari'],
        //         storageState: '.auth/app/appStorageState.json',
        //     },
        //     dependencies: ['setup'],
        // },
    ],
});
