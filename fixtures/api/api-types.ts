/** Supported authentication schemes for API requests */
export type AuthType = 'Bearer' | 'Token' | 'Basic';

/**
 * Parameters for making an API request.
 * @typedef {Object} ApiRequestParams
 * @property {'POST' | 'GET' | 'PUT' | 'DELETE' | 'PATCH'} method - The HTTP method to use.
 * @property {string} url - The endpoint URL for the request.
 * @property {string} [baseUrl] - The base URL to prepend to the endpoint.
 * @property {Record<string, unknown> | null} [body] - The request payload, if applicable.
 * @property {string} [headers] - Authentication token for the Authorization header.
 * @property {AuthType} [authType] - Authentication scheme to use (default: 'Bearer').
 */
export type ApiRequestParams = {
    method: 'POST' | 'GET' | 'PUT' | 'DELETE' | 'PATCH';
    url: string;
    baseUrl?: string;
    body?: Record<string, unknown> | null;
    headers?: string;
    authType?: AuthType;
};

/**
 * Response from an API request.
 * @template T
 * @typedef {Object} ApiRequestResponse
 * @property {number} status - The HTTP status code of the response.
 * @property {T} body - The response body.
 */
export type ApiRequestResponse<T = unknown> = {
    status: number;
    body: T;
};

// define the function signature as a type
export type ApiRequestFn = <T = unknown>(
    params: ApiRequestParams
) => Promise<ApiRequestResponse<T>>;

// grouping them all together
export type ApiRequestMethods = {
    apiRequest: ApiRequestFn;
};
