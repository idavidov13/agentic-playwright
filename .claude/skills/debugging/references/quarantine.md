# Quarantine

Reproduce and investigate the root cause first; do not add retries to hide a flake. If it cannot be fixed now, propose quarantine with evidence and get human approval for the owner and expiry; never invent them. Use declaration form so fixtures do not run:

```typescript
test.fixme(
    'cart badge updates',
    {
        annotation: {
            type: 'quarantine',
            description: 'owner=@handle; until=2028-12-01; issue=#123',
        },
    },
    async ({ page }) => {
        // Existing test body.
    }
);
```

ESLint validates the owner and calendar date. The scheduled Quarantine report lists expired quarantines in the GitHub Actions job summary; run `node lint/quarantine-report.mjs` locally. Contract mismatches remain `test.skip` with `// FIXME: <ticket-url>`.
