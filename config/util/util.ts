/**
 * Utility service configuration object.
 * Contains URL configuration for utility/helper services.
 *
 * For API endpoints, use enums from `enums/` folder.
 */
export const utilityConfig = {
    /** Utility service base URL — from `process.env.UTILITY_URL` (declared in `env/.env.example`). */
    baseUrl: process.env.UTILITY_URL!,
};
