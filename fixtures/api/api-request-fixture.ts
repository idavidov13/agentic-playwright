import { test as base } from '@playwright/test';
import { apiRequest as apiRequestOriginal } from './plain-function';
import {
    ApiRequestFn,
    ApiRequestMethods,
    ApiRequestParams,
    ApiRequestResponse,
} from './api-types';

export const test = base.extend<ApiRequestMethods>({
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
