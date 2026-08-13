import { test as base } from '@playwright/test';
import { apiRequest } from '../api/plain-function';

/**
 * Helper fixtures for important, recurring API-driven setup and teardown.
 *
 * IMPORTANT: Most API calls should be made directly with the `apiRequest` fixture
 * inside tests, `beforeEach`, or `afterEach`. Do NOT create a helper fixture for
 * every endpoint. Helper fixtures are reserved for critical, multi-step operations
 * that are reused across many test files and benefit from automatic lifecycle management.
 *
 * WORKFLOW:
 * Playwright's fixture lifecycle guarantees:
 *   1. Setup code (before `use()`) runs BEFORE the test
 *   2. Data passed to `use()` is available in the test via destructuring
 *   3. Teardown code (after `use()`) runs AFTER the test, even on failure
 *
 * WHEN TO CREATE A HELPER FIXTURE:
 * - The same multi-step setup/teardown is copy-pasted across 3+ test files
 * - Complex preconditions require multiple API calls in sequence
 * - Guaranteed teardown is critical (e.g., deleting test users, revoking tokens)
 *
 * WHEN TO USE `apiRequest` FIXTURE DIRECTLY INSTEAD:
 * - One-off API calls in a single test or test file
 * - API assertions (status codes, response validation)
 * - Simple setup in `beforeEach` / teardown in `afterEach`
 * - Calls specific to a single test describe block
 *
 * HOW TO ADD A NEW HELPER FIXTURE:
 * 1. Define the return type (or use a Zod schema's inferred type)
 * 2. Add the type to `HelperFixtures` below
 * 3. Implement the fixture with the setup → use() → teardown pattern
 * 4. It is automatically available in tests (already merged in test-options.ts)
 *
 * NOTE: Helper fixtures use `plain-function.ts` internally (not the `apiRequest`
 * fixture) because fixture-level code needs the raw `request` context. Tests
 * themselves should always use the `apiRequest` fixture from `test-options.ts`.
 *
 * @example
 * ```ts
 * import { expect, test } from '../../../fixtures/pom/test-options';
 *
 * test('should display created resource', async ({ createdResource, appPage }) => {
 *     // createdResource was set up before this test runs
 *     await appPage.navigateToResource(createdResource.id);
 *     await expect(appPage.resourceName).toHaveText(createdResource.name);
 *     // createdResource is torn down automatically after this test
 * });
 * ```
 */

// ==================== Types ====================

/**
 * Example resource type -- replace with your actual API response type
 * or use `zOutput<typeof YourSchema>` for Zod-inferred types.
 */
type ResourceResponse = {
    id: string;
    name: string;
};

/**
 * Helper fixture type definitions.
 * Add new setup/teardown fixtures here as you create them.
 */
export type HelperFixtures = {
    /**
     * Creates a resource via API before the test and deletes it after.
     * Replace this example with your actual setup/teardown operations.
     */
    createdResource: ResourceResponse;
};

// ==================== Fixtures ====================

export const test = base.extend<HelperFixtures>({
    /**
     * Example helper fixture: creates a resource before the test, cleans up after.
     *
     * Replace the API endpoints, payload, and types with your actual application's API.
     * Use Zod schemas from `fixtures/api/schemas/` for type-safe response parsing.
     *
     * @param {APIRequestContext} request - Playwright request context (injected automatically).
     * @param {function} use - Playwright fixture lifecycle callback.
     */
    createdResource: async ({ request }, use) => {
        // ── SETUP: Runs before the test ──────────────────────────────
        const { body } = await apiRequest({
            request,
            method: 'POST',
            url: '/api/resources',
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
            body: { name: `test-resource-${Date.now()}` },
        });

        const resource = body as ResourceResponse;

        // ── YIELD: Passes data to the test ───────────────────────────
        await use(resource);

        // ── TEARDOWN: Runs after the test (even on failure) ──────────
        await apiRequest({
            request,
            method: 'DELETE',
            url: `/api/resources/${resource.id}`,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    },
});
