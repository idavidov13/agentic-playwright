---
name: selectors
description: Use when choosing a locator for an element, writing or reviewing locators in a page object, or exploring the live app before any UI code. Not for the page-object class shape or registration (see `page-objects`) or for the CLI commands themselves (see `playwright-cli`).
---

# Selectors

## Critical

- Priority order: `getByRole` > `getByLabel` > `getByPlaceholder` > `getByText` > `getByTestId`. Move to the next option only when the previous one is not feasible. One exception: a labelled form field takes `getByLabel('Email')` over `getByRole('textbox', { name: 'Email' })`.

    ```typescript
    // CORRECT
    page.getByRole('button', { name: 'Submit' });
    // WRONG
    page.locator('.btn-primary');
    ```

- Never XPath (`page.locator('//...')`, `'xpath=...'`). CSS class or id selectors only as a last resort after every semantic option is ruled out.
- Exploration with `playwright-cli` is mandatory before any selector is written. No guessing from wireframes, docs or screenshots. If the app cannot be reached or auth fails, stop and notify the human; never ship placeholder locators.
- Strings inside `getByText(...)` come from `enums/{area}/*` (`Messages.LOGIN_ERROR`); the text is captured from the live app, never guessed (`enums`).
- Every page object for a form or CRUD screen has feedback selectors: success, error, field validation, and toast, loading or empty state where the app shows them.

## Procedure

1. Read the URL: `grep '^APP_URL' env/.env.${ENVIRONMENT:-dev}`. No env file → ask the human for the URL.
2. `playwright-cli open <APP_URL>`, then `playwright-cli snapshot`; commands in `playwright-cli`. Explore in the auth state the spec will run in: the `chromium` project starts signed in, so sign in through the login page first unless the spec calls `resetStorageState()`. The page fails to load or needs auth → stop per `references/exploration-workflow.md`.
3. Walk the feature as a user: snapshot, act, snapshot. Trigger each form submit and CRUD action. Record every element's role, accessible name, label, placeholder or test id, and the exact text of every message.
4. List the paths the page must support (happy, validation, error, edge); each path names the feedback locator that proves it.
5. Choose each locator by the priority order (`references/locator-choice.md`), add the feedback locators (`references/feedback-selectors.md`), and write them into the class per `page-objects`.

## References

- `references/exploration-workflow.md`: what to observe at each state and the stop-and-notify protocol when the app is unreachable.
- `references/locator-choice.md`: correct form per tier, exact and scoped matches, multi-match and "stale" symptoms, elements with no accessible name.
- `references/feedback-selectors.md`: the feedback types to capture and the locator for each.
