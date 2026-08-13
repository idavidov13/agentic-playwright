/**
 * Application configuration object.
 * Contains URL configuration for the main application.
 *
 * For route paths and API endpoints, use enums from `enums/app/app.ts`.
 */
export const appConfig = {
    /** Frontend application URL */
    appUrl: process.env.APP_URL,
    /** Backend API URL */
    apiUrl: process.env.API_URL,
};
