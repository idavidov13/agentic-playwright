/**
 * Universal invalid-value arrays for negative/validation API tests.
 *
 * Import these in spec files and iterate with `for...of` loops — do NOT
 * redefine them inline. Field-specific boundary/range violations (e.g.,
 * out-of-range values for a `number` constrained to `1..5`) may stay inline
 * in the spec file; see `.claude/skills/api-testing/SKILL.md` (Phase 6).
 *
 * The file is `.ts` (not `.json`) because JSON cannot represent `undefined`.
 * Tuples are `as const` so the array is `readonly` and values keep their
 * narrow literal types.
 */

export const INVALID_STRING_VALUES = [123, true, null, undefined] as const;

export const INVALID_NUMBER_VALUES = [
    'string',
    '123',
    true,
    null,
    undefined,
] as const;

export const INVALID_BOOLEAN_VALUES = ['yes', 1, 0, null, undefined] as const;

export const INVALID_UUID_VALUES = [
    'not-a-uuid',
    '',
    123,
    null,
    undefined,
] as const;

export const INVALID_ENUM_VALUES = [
    'invalidValue',
    '',
    123,
    null,
    undefined,
] as const;

export const INVALID_ARRAY_VALUES = [
    'string',
    123,
    null,
    undefined,
    {},
] as const;

export const INVALID_OBJECT_VALUES = [
    'string',
    123,
    null,
    undefined,
    [],
] as const;
