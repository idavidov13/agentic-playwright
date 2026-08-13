import { z } from 'zod/v4';
import type { output as zOutput } from 'zod/v4';

/*
 * Error-response schemas for the demo API (practicesoftwaretesting.com).
 *
 * FIXME: the OpenAPI spec documents these status codes but not their body
 * schemas, so the shapes below are captured from live responses per the
 * "Explore Before Generate" fallback (missing docs flagged upstream).
 * Re-verify whenever the spec adds error schemas.
 */

/**
 * Schema for 401 Unauthorized responses.
 * Live examples: {"error": "Unauthorized"}, {"error": "Invalid login request"}.
 */
export const UnauthorizedResponseSchema = z.strictObject({
    error: z.string(),
});

/**
 * Schema for 403 Forbidden responses.
 * FIXME: shape not yet observed live — Laravel convention, unverified.
 */
export const ForbiddenResponseSchema = z.strictObject({
    message: z.string(),
});

/**
 * Schema for 404 Not Found responses.
 * Live example: {"message": "Requested item not found"}.
 */
export const NotFoundResponseSchema = z.strictObject({
    message: z.string(),
});

/**
 * Schema for 422 Unprocessable Entity (validation) responses.
 * Live shape: a map of field name -> array of validation messages.
 */
export const UnprocessableEntityResponseSchema = z.record(
    z.string(),
    z.array(z.string())
);

// Type exports
export type UnauthorizedResponse = zOutput<typeof UnauthorizedResponseSchema>;
export type ForbiddenResponse = zOutput<typeof ForbiddenResponseSchema>;
export type NotFoundResponse = zOutput<typeof NotFoundResponseSchema>;
export type UnprocessableEntityResponse = zOutput<
    typeof UnprocessableEntityResponseSchema
>;
