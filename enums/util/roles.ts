/**
 * User roles shared across all application areas.
 * Extend with app-specific roles only if they are used by more than one area;
 * otherwise define them in `enums/{area}/`.
 */
export enum Roles {
    ADMIN = 'admin',
    USER = 'user',
    GUEST = 'guest',
}
