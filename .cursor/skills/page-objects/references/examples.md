# Page Object Examples

Three end-to-end walkthroughs aligned with the 8-phase `ai-native-workflow`. Each example uses the in-skill phase numbering (Phase 1-6 in `page-objects/SKILL.md`); for the global flow see `ai-native-workflow/SKILL.md`.

## Example 1: Add a brand-new page end-to-end

User says: _"Add a `SettingsPage` page object for `/settings` with a dark-mode toggle and a profile-save form."_

Actions:

1. **Phase 1** — `ls pages/` → `app`. Confirm enums: `Messages.PROFILE_SAVED` / `PROFILE_SAVE_FAILED` — if missing, extend via the `enums` skill with text captured via `playwright-cli`.
2. **Phase 2** — Run `playwright-cli` to navigate to `/settings`, snapshot the DOM, try the toggle and the save form, capture every role/label/feedback-message text.
3. **Phase 3** — Plan: happy-path save, validation errors per profile field, toast messages on success/failure, dark-mode toggle state.
4. **Phase 4** — Create `pages/app/settings.page.ts` with three locator sections, a `saveProfile(overrides?)` action method, and a `saveProfileAndVerify()` verification method.
5. **Phase 5** — Register `settingsPage: SettingsPage` in `page-object-fixture.ts`.
6. **Phase 6** — Consume in `tests/app/functional/settings.spec.ts` via `async ({ settingsPage }) => { ... }`.

## Example 2: Add a new locator and action to an existing page

User says: _"Add a `forgotPassword` link and a `clickForgotPassword()` method to `AppPage`."_

Actions:

1. **Phase 2** — Re-explore with `playwright-cli` for the forgot-password element (role, label). Do not assume it's `getByRole('link', { name: 'Forgot password?' })` — verify.
2. **Phase 4** — Add `get forgotPasswordLink(): Locator` in the Interactive Locators section and `async clickForgotPassword(): Promise<void>` in the Actions section, with JSDoc.
3. No Phase 5 change — existing registration covers it.
4. **Phase 6** — Consume from tests.

## Example 3: Extract a reusable component

User says: _"The same notification-toast element shows up on 3 pages — extract it."_

Actions:

1. **Phase 2** — Capture the toast's locators (role, accessible name, close button) via `playwright-cli`.
2. **Phase 4** — Create `pages/components/notification.component.ts` as `NotificationComponent` following the `NavigationComponent` pattern.
3. Compose into each consuming page as `readonly notification: NotificationComponent;` in the constructor.
4. Update the 3 pages to call `this.notification.xxx` instead of duplicating locators.
5. No fixture change — components are consumed through the page object, not registered separately.
