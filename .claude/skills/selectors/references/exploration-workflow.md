# Exploration workflow

`playwright-cli` runs in a shell, not in the test runner, so the URL comes from the env file by hand: `grep '^APP_URL' env/.env.dev` (or the file named by `ENVIRONMENT`). The command reference is the `playwright-cli` skill.

```bash
playwright-cli open <APP_URL>
playwright-cli snapshot
playwright-cli click <ref>
playwright-cli snapshot
```

## Auth state

`playwright-cli open` starts signed out. The `chromium` project loads the storage state from `tests/{area}/*.setup.ts`, so a spec runs signed in unless it calls `resetStorageState()` (`test-standards`). Pages that render differently for a signed-in user (pre-filled or hidden fields, extra menu items) are explored in the state the spec will use: sign in through the login page with `playwright-cli` first, or explore signed out and call `resetStorageState()` in the spec.

## What to observe at each state

- Forms: inputs, labels, placeholders, dropdowns, checkboxes, radios.
- Buttons and links: submit, cancel, create, edit, delete, navigation, tabs.
- Feedback: success banners, error messages, per-field validation text, toasts, spinners, empty states.
- Dynamic content: modals, expanded sections, rows added after an action.

Submit each form with valid and with invalid input and run each CRUD action, so the real success, error and validation messages render. Copy the text exactly; it becomes an enum member (`enums`).

## When the page fails to load or needs auth

1. Stop. Do not guess selectors and do not write placeholder locators.
2. Tell the human the exact state: "The application at `<URL>` returned [error / login page / blank screen]. I need [credentials / a different URL / a storage state] before I can continue."
3. Wait for the remediation, re-open the page, confirm it renders, then continue.

A redirect to the login page is a loaded page when the login page is the one under test.
