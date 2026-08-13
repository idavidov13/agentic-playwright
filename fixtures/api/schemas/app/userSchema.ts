import { z } from 'zod/v4';
import type { output as zOutput } from 'zod/v4';

/**
 * Schema for user login response.
 * Customize this schema based on your API response structure.
 */
export const UserResponseSchema = z.strictObject({
    access_token: z.string(),
    token_type: z.string(),
    expires_in: z.int(),
});

/**
 * Schema for user login request payload.
 */
export const LoginRequestSchema = z.strictObject({
    email: z.email(),
    password: z.string().min(1),
});

// Type exports
export type UserResponse = zOutput<typeof UserResponseSchema>;
export type LoginRequest = zOutput<typeof LoginRequestSchema>;
