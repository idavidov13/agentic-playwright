# Selector Troubleshooting

## My selector matches multiple elements

**Cause:** Two elements share the same accessible name or text content.
**Fix:** Add `{ exact: true }` to narrow text matches, use a more specific role, or **scope** to a parent: `page.getByRole('form', { name: 'Login' }).getByRole('button', { name: 'Submit' })`.

## I'm about to write an XPath because nothing semantic works

**Fix:** Forbidden. Re-snapshot with `playwright-cli` — often there IS a role or label hidden inside a custom component. If truly nothing semantic exists, coordinate with engineering to add a `data-testid` and use `getByTestId('...')`.

## I used `page.locator('.btn-primary')` because the button has no accessible name

**Cause:** The markup lacks an accessible name (`<button><svg/></button>` is a common culprit).
**Fix:** First, re-check the snapshot — ARIA `aria-label` or a visible icon label may give you a semantic hook. If not, add `data-testid` in collaboration with engineering; use `getByTestId(...)` until then. Class-based locators are brittle and must not ship.

## My page object has form inputs and a submit button but no error / success locators

**Cause:** Feedback & Validation Message Selectors section was skipped.
**Fix:** Re-explore (Phase 2), capture the rendered messages, encode them as `Messages.*` in `enums/{area}/*.ts` (via the `enums` skill), and add the locators. Ship nothing until the feedback selectors are in.

## I want to grep the DOM from dev tools and copy a CSS chain

**Fix:** Forbidden as the default. Re-explore with `playwright-cli` and pick the semantic strategy from the Priority Order. The dev-tools CSS chain is almost always brittle (generated class names, index-based selectors).

## My locator returns "stale" elements after navigation

**Cause:** Misdiagnosis. `Locator` is lazy and always re-queries the DOM when an action runs — it doesn't "go stale".
**Fix:** The real problem is one of: (a) the element legitimately isn't there yet → use `await expect(locator).toBeVisible()` to wait, (b) the selector no longer matches the new DOM → re-snapshot and update the selector, or (c) frame/iframe context changed → scope with `frameLocator(...)`.

## I need to use `data-testid` but engineering hasn't added one

**Fix:** Escalate with engineering — `data-testid` attributes are a legitimate semantic hook that shouldn't require negotiation for every field. Document the request, prioritise accessibility improvements where possible (adding `aria-label`, labels, or roles often fixes the problem better than `data-testid`).
