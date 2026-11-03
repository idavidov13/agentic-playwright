import { ApiEndpoints } from '../../../enums/app/app';
import {
    UserResponse,
    UserResponseSchema,
} from '../../../fixtures/api/schemas/app/userSchema';
import {
    UnauthorizedResponse,
    UnauthorizedResponseSchema,
} from '../../../fixtures/api/schemas/util/errorResponseSchema';
import { expect, test } from '../../../fixtures/pom/test-options';
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

/*
 * DELIBERATELY MINIMAL TEMPLATE — not an example of full coverage.
 *
 * This spec demonstrates the scaffold's core patterns (apiRequest fixture,
 * enum endpoint, schema parse, data-driven loop) against the demo API only.
 * A real endpoint spec MUST cover the full status-code matrix from the
 * api-testing skill (coverage matrix): empty body, per-field omission, per-field
 * invalid-type loops, 405, and every status code in the OpenAPI contract.
 * Do NOT copy this file's coverage level as the standard.
 */
test.describe('api/login', () => {
    test(
        'should return 200 and user data for valid credentials',
        { tag: '@api' },
        async ({ apiRequest }) => {
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
        }
    );

    for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
        test(
            `should return 401 for invalid credentials - ${description} - email: ${email} - password: ${password}`,
            { tag: '@api' },
            async ({ apiRequest }) => {
                const { status, body } = await apiRequest<UnauthorizedResponse>(
                    {
                        method: 'POST',
                        url: ApiEndpoints.LOGIN,
                        baseUrl: process.env.API_URL,
                        body: { email, password },
                    }
                );

                expect(status).toBe(401);
                expect(UnauthorizedResponseSchema.parse(body)).toBeTruthy();
            }
        );
    }
});
