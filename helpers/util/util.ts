/**
 * Formats a date value as a long US-English date string (e.g. "July 2, 2026").
 *
 * @param value - Epoch milliseconds or a date string parseable by `new Date()`.
 * @returns The formatted date, e.g. `"July 2, 2026"`.
 */
export function formatDate(value: number | string): string {
    return new Date(value).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
}
