# Tags

One tag per test, in the options object: `test('…', { tag: '@smoke' }, async () => {})`.

| Tag            | Covers                                                               | Suite                                     |
| -------------- | -------------------------------------------------------------------- | ----------------------------------------- |
| `@smoke`       | Critical-path functional tests, run first and most often             | `npm run test:smoke`                      |
| `@sanity`      | Key functionality verification                                       | `npm run test:sanity`                     |
| `@regression`  | Full coverage of one behaviour, including data-driven negative cases | `npm run test:regression`                 |
| `@e2e`         | One multi-feature user journey per test                              | `npm run test:e2e`                        |
| `@api`         | API contract and schema validation, whatever its importance          | `npm run test:api`                        |
| `@destructive` | Mutates shared/global state (see `destructive-tests.md`)             | `npm run test:destructive`, single worker |

`npm test` runs every tag except `@destructive`. Each suite filters with `--grep`, so a test belongs to exactly one suite.

## Wrong forms

```typescript
// not a valid tag
test('should login', { tag: '@functional' }, async () => {});
// one tag only; @destructive replaces the importance tag
test('should reset', { tag: ['@regression', '@destructive'] }, async () => {});
// tags go on tests, never on describe
test.describe('Login @smoke', () => {});
```
