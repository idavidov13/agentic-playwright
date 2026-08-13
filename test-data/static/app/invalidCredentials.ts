/**
 * Domain-specific invalid credentials for login tests.
 *
 * Three curated sets used by authentication negative tests:
 * - `INVALID_EMAILS` — email strings that should be rejected as malformed.
 * - `INVALID_PASSWORDS` — password strings that should be rejected as weak / malformed.
 * - `INVALID_LOGIN_ATTEMPTS` — paired `{ description, email, password }` objects
 *   for data-driven login-rejection tests that iterate full scenarios.
 *
 * Format: `.ts` with `as const` exports.
 * Static data files in this scaffold are TypeScript only; they may export
 * only literal values (no runtime imports, no functions, no computed values).
 * See `.claude/skills/data-strategy/SKILL.md` (Phase 3, Tier 2 — domain-specific).
 */

export const INVALID_EMAILS = [
    '',
    'plaintext',
    'missing-at-sign.com',
    'missing@domain',
    '@missing-local.com',
    'double@@at.com',
    'spaces in@email.com',
    'invalid@.com',
    'invalid@domain',
    'invalid@domain..com',
    'user@domain,com',
    'user name@domain.com',
] as const;

export const INVALID_PASSWORDS = [
    '',
    '123',
    'short',
    'NoNumber!',
    'nouppercase123!',
    'NOLOWERCASE123!',
    'NoSpecialChar123',
    '   spaces123!',
    'trailing ',
    ' leading',
] as const;

export const INVALID_LOGIN_ATTEMPTS = [
    {
        description: 'valid email with wrong password',
        email: 'test.user@example.com',
        password: 'WrongPassword123!',
    },
    {
        description: 'valid email with incorrect password',
        email: 'admin@test.com',
        password: 'IncorrectPass456$',
    },
    {
        description: 'invalid email format with valid password',
        email: 'invalid-email',
        password: 'ValidPassword123!',
    },
    {
        description: 'missing local part in email with valid password',
        email: '@missinglocal.com',
        password: 'SecurePass789#',
    },
    {
        description: 'empty email and password',
        email: '',
        password: '',
    },
    {
        description: 'invalid email format with short password',
        email: 'not-an-email',
        password: '123',
    },
    {
        description: 'incomplete email domain with short password',
        email: 'missing@domain',
        password: 'short',
    },
] as const;
