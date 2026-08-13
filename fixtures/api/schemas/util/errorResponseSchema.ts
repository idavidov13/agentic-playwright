import { z } from 'zod/v4';
import type { output as zOutput } from 'zod/v4';

/**
 * Schema for 400 Bad Request responses.
 */
export const BadRequestResponseSchema = z.strictObject({
    message: z.union([z.string(), z.array(z.string())]),
    error: z.literal('Bad Request'),
    statusCode: z.literal(400),
});

/**
 * Schema for 401 Unauthorized responses.
 */
export const UnauthorizedResponseSchema = z.strictObject({
    message: z.literal('Unauthorized'),
    statusCode: z.literal(401),
});

/**
 * Schema for 403 Forbidden responses.
 */
export const ForbiddenResponseSchema = z.strictObject({
    message: z.string(),
    error: z.literal('Forbidden'),
    statusCode: z.literal(403),
});

/**
 * Schema for 404 Not Found responses.
 */
export const NotFoundResponseSchema = z.strictObject({
    message: z.string(),
    error: z.literal('Not Found'),
    statusCode: z.literal(404),
});

// Type exports
export type BadRequestResponse = zOutput<typeof BadRequestResponseSchema>;
export type UnauthorizedResponse = zOutput<typeof UnauthorizedResponseSchema>;
export type ForbiddenResponse = zOutput<typeof ForbiddenResponseSchema>;
export type NotFoundResponse = zOutput<typeof NotFoundResponseSchema>;
