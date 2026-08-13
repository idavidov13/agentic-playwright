# Selector Examples

## Example 1: Generate selectors for a new login page

User says: _"Create the locators for the login page."_

Actions:

1. **Phase 1** — Run `playwright-cli open <APP_URL>` and `playwright-cli snapshot`. If the page redirects to login, that IS the login page — proceed. If it fails, stop and notify.
2. **Phase 2** — Snapshot the form; identify: email input (labelled), password input (labelled), submit button (role="button", name "Login"), error banner (role="alert" or `getByText(...)`), forgot-password link (role="link").
3. **Phase 3** — Plan: happy-path login, wrong-password error, empty fields validation, forgot-password navigation.
4. **Phase 4** — Generate using the priority order:
    - `getByLabel('Email')` for the email input (labelled → Tier 2).
    - `getByLabel('Password')` for the password input.
    - `getByRole('button', { name: 'Login' })` for the submit button (Tier 1).
    - `getByText(Messages.LOGIN_ERROR)` for the error banner (use enum; extend via `enums` skill if the member doesn't exist).
    - `getByRole('link', { name: 'Forgot password?' })` for the link.

## Example 2: Add missing feedback selectors to an existing page object

User says: _"The `AppPage` login works but our test can't assert on success — it only has form locators."_

Actions:

1. **Phase 2** — Re-explore: after a successful login, what feedback does the UI show? Username display? Success toast? Redirect to dashboard?
2. Capture the exact rendered strings with `playwright-cli snapshot`.
3. **Phase 4** — Add the missing feedback locators to `AppPage`:
    - `successMessage` (or `username` if visibility of the user's name is the success signal).
    - `errorMessage` for the failure path (already present).
    - `requiredFieldError` if empty-field validation is in scope.
4. Every new `Messages.*` reference must exist in `enums/app/app.ts` — extend via the `enums` skill if needed.

## Example 3: Choose between `getByRole` and `getByLabel` for a form field

User says: _"The email input has a role of `textbox` and a `<label>Email</label>`. Which do I use?"_

Answer: **`getByLabel('Email')`**.

Reasoning: When a form input has an associated label, `getByLabel()` is both more readable (matches how users perceive the field) and more resilient (a role change from `textbox` to a custom `combobox` doesn't break the locator). `getByRole('textbox', { name: 'Email' })` works but is a second-choice. Reserve `getByRole('textbox', ...)` for inputs **without** a label.
