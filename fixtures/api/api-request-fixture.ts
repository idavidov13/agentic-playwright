import { test as base } from '@playwright/test';
import { loadUserAccessToken } from '../../helpers/app/createStorageState';
import { apiRequest as apiRequestOriginal } from './plain-function';
import {
    ApiRequestFn,
    ApiRequestMethods,
    ApiRequestParams,
    ApiRequestResponse,
} from './api-types';

/**
 * Worker-scoped fixtures of the API layer.
 * `accessTokenLoaded` runs once per worker process before any test and
 * publishes the token minted by the `setup-api` project as `process.env.ACCESS_TOKEN`.
 */
type ApiWorkerFixtures = {
    accessTokenLoaded: void;
};

export const test = base.extend<ApiRequestMethods, ApiWorkerFixtures>({
    accessTokenLoaded: [
        async ({}, use): Promise<void> => {
            loadUserAccessToken();
            await use();
        },
        { scope: 'worker', auto: true },
    ],

    /**
     * Provides a function to make API requests.
     * Uses the Playwright request context for HTTP calls.
     *
     * @param {object} request - The request object.
     * @param {function} use - The use function to provide the API request function.
     */
    apiRequest: async ({ request }, use) => {
        const apiRequestFn: ApiRequestFn = async <T = unknown>({
            method,
            url,
            baseUrl,
            body = null,
            headers,
            authType,
        }: ApiRequestParams): Promise<ApiRequestResponse<T>> => {
            const response = await apiRequestOriginal({
                request,
                method,
                url,
                baseUrl,
                body,
                headers,
                authType,
            });

            return {
                status: response.status,
                body: response.body as T,
            };
        };

        await use(apiRequestFn);
    },
});
