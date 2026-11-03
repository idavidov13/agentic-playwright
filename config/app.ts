/**
 * Application configuration object.
 * Contains URL configuration for the main application.
 *
 * For route paths and API endpoints, use enums from `enums/app/app.ts`.
 */
export const appConfig = {
    /** Frontend application URL loaded from the APP_URL env variable */
    appUrl: process.env.APP_URL!,
    /** Backend API URL loaded from the API_URL env variable */
    apiUrl: process.env.API_URL!,
};
