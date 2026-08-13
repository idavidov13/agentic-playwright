import { faker } from '@faker-js/faker';
import {
    UserResponse,
    UserResponseSchema,
} from '../../../fixtures/api/schemas/app/userSchema';

/**
 * Generates a valid user object with randomized data using Faker.
 * The generated data conforms to the UserResponseSchema structure.
 *
 * This factory ensures test isolation by creating unique data for each test run,
 * preventing data collision in parallel execution.
 *
 * @param {Partial<UserResponse>} overrides - Optional partial user object to override default values.
 * @returns {UserResponse} A valid user object matching the UserResponseSchema.
 *
 * @example
 * // Generate a random user
 * const user = generateUser();
 *
 * @example
 * // Generate a user with specific email
 * const adminUser = generateUser({ email: 'admin@test.com' });
 */
export const generateUser = (
    overrides?: Partial<UserResponse>
): UserResponse => {
    const defaultUser: UserResponse = {
        access_token: faker.string.alphanumeric(64),
        token_type: 'bearer',
        expires_in: faker.number.int({ min: 60, max: 3600 }),
    };

    const mergedUser = { ...defaultUser, ...overrides };

    // Validate against schema to ensure type safety
    return UserResponseSchema.parse(mergedUser);
};

/**
 * Generates login credentials for testing purposes.
 * Creates a unique email and password combination.
 *
 * @param {object} overrides - Optional overrides for email and/or password.
 * @param {string} overrides.email - Override the generated email.
 * @param {string} overrides.password - Override the generated password.
 * @returns {{ email: string; password: string }} Valid login credentials.
 *
 * @example
 * // Generate random credentials
 * const creds = generateLoginCredentials();
 *
 * @example
 * // Generate credentials with specific email
 * const creds = generateLoginCredentials({ email: 'specific@test.com' });
 */
export const generateLoginCredentials = (
    overrides?: Partial<{ email: string; password: string }>
): { email: string; password: string } => {
    return {
        email: overrides?.email ?? faker.internet.email(),
        password:
            overrides?.password ??
            faker.internet.password({
                length: 12,
                memorable: false,
                pattern: /[A-Za-z0-9!@#$%]/,
            }),
    };
};
