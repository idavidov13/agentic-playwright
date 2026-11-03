---
name: page-objects
description: Use when creating a page object or component under pages/**, adding locators or action methods to one, or registering it as a fixture. Not for choosing a selector or the exploration workflow (see `selectors`) or for fixture internals (see `fixtures`).
---

# Page Objects

## Critical

- Explore the live page with `playwright-cli` before writing any locator (`selectors`). If the app is unreachable, stop and say so; never ship placeholder locators.
- Locators are `get` accessors returning `Locator`. The constructor is `constructor(private readonly page: Page)`. Imports come from `@playwright/test`, never from `fixtures/pom/test-options.ts`.
- JSDoc is **Forbidden** on locator getters and on any method returning a `Locator`. JSDoc with `@param` and `@returns` is required on every action and verification method.

    ```typescript
    // CORRECT
    get submitButton(): Locator {
        return this.page.getByRole('button', { name: 'Submit' });
    }
    // WRONG
    /** The submit button. */
    get submitButton(): Locator {
        return this.page.getByRole('button', { name: 'Submit' });
    }
    ```

- A page object for a form or CRUD screen has three groups: interactive locators, feedback locators (success, error, field validation), action methods. Feedback locators are not optional; `selectors` lists what to capture.
- Strings inside `getByText(...)` come from `enums/{area}/*` (`Messages.LOGIN_ERROR`), never literals.
- Action methods do not assert; a verification method named `xxxAndVerify()` may call `expect`. Waits are `page.waitForResponse(...)` or web-first assertions, never `page.waitForTimeout(...)`.
- A fragment shared by several pages (header, modal, sidebar) is a component in `pages/components/`, held as `readonly nav: NavigationComponent` and created in the constructor.
- Every new page object is registered in `fixtures/pom/page-object-fixture.ts`; tests receive it from the fixture (`fixtures`).

## Procedure

1. Run `ls pages/` to resolve `{area}`. File: `pages/{area}/<name>.page.ts`, or `pages/components/<name>.component.ts` for a fragment.
2. Explore the page with `playwright-cli` per `selectors`; record each element's role, accessible name, label or test id, and the exact text of every feedback message.
3. A message or route that has no enum member yet is added per `enums` before the class is written.
4. Write the class from `references/class-pattern.md`: locators in priority order (`selectors`), feedback locators, action methods with explicit return types and JSDoc.
5. A fragment used by more than one page becomes a component per `references/components.md`.
6. Register: import the class, add it to `FrameworkFixtures`, add the fixture body, each shaped like the `appPage` entries in `fixtures/pom/page-object-fixture.ts`. No `mergeTests` change.
7. Run `npm run lint`; write or update the spec per `test-standards` and run it.

## References

- `references/class-pattern.md`: the full class with the three groups, one action method and one verification method.
- `references/components.md`: a component, its composition into a page, when to split a large page object.
