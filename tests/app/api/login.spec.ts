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
