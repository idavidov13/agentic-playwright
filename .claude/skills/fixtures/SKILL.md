---
name: fixtures
description: Use when registering a page object as a fixture, adding a setup/teardown fixture, adding a new fixture category, or deciding whether reusable code is a fixture or a plain helper. Not for the page-object class itself (see `page-objects`) or plain functions (see `helpers`).
---

# Fixtures

## Critical

- Tests receive page objects and API access through fixtures. `new AppPage(page)` inside a spec is forbidden.
- Spec files import `test` and `expect` from `fixtures/pom/test-options.ts`, never from `@playwright/test`.
- Page-object fixtures live in `fixtures/pom/page-object-fixture.ts`, lifecycle fixtures in `fixtures/helper/helper-fixture.ts`, functions without a lifecycle in `helpers/` (`helpers`). No per-page fixture files.
- Every fixture is typed in `FrameworkFixtures` or `HelperFixtures`.
- Setup runs before `await use(data)`, teardown after it. Code placed before `use()` never tears down.

    ```typescript
    // CORRECT
    const user = await createUser();
    await use(user);
    await deleteUser(user.id);
    // WRONG: teardown before use() runs before the test
    await deleteUser(user.id);
    await use(user);
    ```

- A new fixture category gets its own `fixtures/<category>/<name>-fixture.ts` and is merged into `fixtures/pom/test-options.ts` with `mergeTests()`.
- One-off API calls use `apiRequest` directly in the test. A helper fixture is only for setup and teardown that recurs past the threshold `api-testing` owns.
- Fixture code parses API bodies with `SchemaName.parse(body)`, never `body as T`. The `expect(SchemaName.parse(body)).toBeTruthy();` form is for spec files.

## Procedure

1. Classify the need. Existing fixtures are the type literals `FrameworkFixtures`, `ApiRequestMethods` and `HelperFixtures`.

    | Need                                                 | Home                                                 |
    | ---------------------------------------------------- | ---------------------------------------------------- |
    | Page object injected into tests                      | extend `fixtures/pom/page-object-fixture.ts`         |
    | Recurring API setup/teardown with guaranteed cleanup | extend `fixtures/helper/helper-fixture.ts`           |
    | One-off API call in one test or describe             | no fixture; `apiRequest` in the test (`api-testing`) |
    | Reusable function with no lifecycle                  | `helpers/` (`helpers`)                               |
    | Something else that needs `page` or `request` via DI | new category: own file, merged with `mergeTests()`   |

    None of the rows fit → ask.

2. Page object: add the property to `FrameworkFixtures` and the body `async ({ page }, use) => { await use(new X(page)); }`, shaped like `appPage` in the real file. No `mergeTests` change.
3. Lifecycle fixture: add the type to `HelperFixtures`; write setup → `use` → teardown per `references/lifecycle.md`, calling `apiRequest` from `fixtures/api/plain-function.ts` with data from a factory (`data-strategy`) and the body parsed with the endpoint's schema before `use`.
4. New category: file skeleton and the `mergeTests()` line per `references/lifecycle.md`.
5. Run `npx tsc --noEmit`, then the spec that consumes the fixture.

## References

- `references/lifecycle.md`: the helper-fixture skeleton, the new-category file and merge, and the four symptoms of a mis-wired fixture.
