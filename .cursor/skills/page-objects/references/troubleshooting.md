# Page Object Troubleshooting

## Test can't find `dashboardPage` (or any page object) on the test context

**Cause:** The page object isn't registered in `FrameworkFixtures` and/or has no fixture body in `page-object-fixture.ts`.
**Fix:** Complete Phase 5 — add the type to `FrameworkFixtures` **and** the implementation to the `base.extend<FrameworkFixtures>({ ... })` block.

## My locator-returning method signature is verbose or I'm splitting field declarations and constructor assignments for every element

**Cause:** Using `readonly field + constructor assignment` for each locator — works identically to `get`, but fights the scaffold's style.
**Fix:** Convert to `get submitButton(): Locator { return this.page.getByRole(...); }`. Both forms are correct (Playwright `Locator` is lazy), but the `get` form is the scaffold convention — terser and keeps locators grouped in the class body.

## I tried `test.use()` to inject the page object and it didn't work

**Cause:** Page objects are consumed through the fixture context, not `test.use`. `test.use` is for Playwright-native options (viewport, storage state, etc.).
**Fix:** Register the page object per Phase 5, then destructure it from the test context (`async ({ dashboardPage }) => { ... }`).

## I'm tempted to `page.waitForTimeout(1000)` inside an action method

**Fix:** Forbidden. Replace with `page.waitForResponse(...)` when waiting for an API call, or with a web-first assertion (`await expect(locator).toBeVisible()`) when waiting for UI state. If neither fits, the page is under-specified — re-explore to find the right signal.

## The `Messages.X` enum member I want to use doesn't exist

**Cause:** The UI text hasn't been encoded yet.
**Fix:** Stop and extend the enum via the `enums` skill — capture the exact text from the live app with `playwright-cli` first. Never hardcode the string in `getByText('...')` as a workaround.

## I copy-pasted a locator from DOM inspector and it uses XPath or a brittle CSS chain

**Cause:** Wrong locator strategy.
**Fix:** Replace with `getByRole` > `getByLabel` > `getByPlaceholder` > `getByText` > `getByTestId` per the `selectors` skill's priority order. If nothing semantic works, coordinate with engineering to add a `data-testid`.

## My page object file is 600+ lines and hard to maintain

**Cause:** One class is covering too many flows.
**Fix:** Split by flow (`SettingsProfilePage`, `SettingsBillingPage`) or extract cross-page fragments into components under `pages/components/`. Keep each page object focused on one screen's worth of interactions.

## Tests work when I run them alone but fail in parallel

**Cause:** Page-object actions rely on shared state or hardcoded identifiers (usernames, emails).
**Fix:** Use a factory (`generateUser()`) from `test-data/factories/{area}/` for dynamic data, and a helper fixture (see `api-testing` Phase 8) if the same setup/teardown is needed across 3+ files.
