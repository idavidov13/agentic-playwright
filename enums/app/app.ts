/**
 * Application-specific constants.
 * Add your application's repeated string values here.
 *
 * @example
 * ```ts
 * import { Messages, ApiEndpoints } from '../../enums/app/app';
 *
 * await expect(page.getByText(Messages.LOGIN_SUCCESS)).toBeVisible();
 * ```
 */

/** Common UI messages */
export enum Messages {
    LOGIN_SUCCESS = 'Successfully logged in',
    LOGIN_FAILED = 'Invalid credentials',
    LOGIN_ERROR = 'Invalid email or password',
    LOGOUT_SUCCESS = 'You have been logged out',
    SESSION_EXPIRED = 'Your session has expired',
    REQUIRED_FIELD = 'This field is required',
}

/** UI route paths */
export enum AppRoutes {
    LOGIN = '/auth/login',
}

/** API endpoint paths */
export enum ApiEndpoints {
    LOGIN = '/users/login',
    LOGOUT = '/users/logout',
    CURRENT_USER = '/users/me',
    REGISTER = '/users/register',
}

/** Storage state file paths */
export enum StorageStatePaths {
    APP = '.auth/app/appStorageState.json',
}
