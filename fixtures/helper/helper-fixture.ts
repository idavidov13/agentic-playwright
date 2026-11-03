import { test as base } from '@playwright/test';
import { z } from 'zod/v4';
import type { output as zOutput } from 'zod/v4';
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
 * - The same multi-step setup/teardown is copy-pasted widely enough to clear
 *   the promotion threshold (api-testing skill Critical, canonical)
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
 * Example response schema -- for a real fixture this belongs in
 * `fixtures/api/schemas/{area}/`, built from the documented API contract.
 * Responses are validated with `.parse()`, never cast with `as`.
 */
const ResourceResponseSchema = z.strictObject({
    id: z.string(),
    name: z.string(),
});
type ResourceResponse = zOutput<typeof ResourceResponseSchema>;

/**
 * Example endpoint path -- for a real fixture this belongs in
 * `enums/{area}/*` (`ApiEndpoints`), never as an inline literal.
 */
const EXAMPLE_RESOURCE_ENDPOINT = '/api/resources';

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
        // Date.now() only reduces the odds of a name collision (same-ms runs
        // across parallel workers can still collide) — a real fixture should
        // generate its data with a Faker factory (test-data/factories/{area}/).
        const { body } = await apiRequest({
            request,
            method: 'POST',
            url: EXAMPLE_RESOURCE_ENDPOINT,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
            body: { name: `test-resource-${Date.now()}` },
        });

        // Validate, don't cast -- a shape mismatch fails here, not mid-test.
        const resource = ResourceResponseSchema.parse(body);

        // ── YIELD: Passes data to the test ───────────────────────────
        await use(resource);

        // ── TEARDOWN: Runs after the test (even on failure) ──────────
        await apiRequest({
            request,
            method: 'DELETE',
            url: `${EXAMPLE_RESOURCE_ENDPOINT}/${resource.id}`,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    },
});
