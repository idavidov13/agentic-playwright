# Quarantine

Reproduce and investigate the root cause first; do not add retries to hide a flake. If it cannot be fixed now, propose quarantine with evidence and get human approval for the owner and expiry; never invent them. Preserve the test’s existing tag and use declaration form so fixtures do not run:

```typescript
test.fixme(
    'cart badge updates',
    {
        tag: '@smoke',
        annotation: {
            type: 'quarantine',
            description:
                'owner=<@github-handle>; until=<YYYY-MM-DD>; issue=<ticket-url>',
        },
    },
    async ({ page }) => {
        // Existing test body.
    }
);
```

The placeholders fail `npm run lint` until the human's values replace them. ESLint (`quarantine/annotation`) validates the owner and the calendar date; expiry is not automatically checked. A test in a data-driven loop keeps its template-literal title.

Contract mismatches remain `test.skip` with `// FIXME: <ticket-url>` on the line above. Nothing else passes: not a bare `test.skip` or `test.fixme`, not the in-body forms (`test.skip(true, ...)`, `testInfo.skip()`, `test.info().fixme()`), not `test.step.skip()`.
