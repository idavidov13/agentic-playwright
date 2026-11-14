# Locator choice

## Correct form per tier

```typescript
// 1. getByRole: buttons, links, headings, navigation, checkboxes
page.getByRole('button', { name: 'Submit' });
page.getByRole('link', { name: 'Dashboard' });
page.getByRole('heading', { name: 'Welcome' });
page.getByRole('checkbox', { name: 'Remember me' });

// 2. getByLabel: form fields with a <label>
page.getByLabel('Email address *');

// 3. getByPlaceholder: inputs without a label
page.getByPlaceholder('Search...');

// 4. getByText: static text and messages, value from an enum
page.getByText(Messages.LOGIN_ERROR);

// 5. getByTestId: when nothing semantic identifies the element
page.getByTestId('nav-menu');
```

The scaffold reads test ids from `data-test` (`testIdAttribute` in `playwright.config.ts`).

## Labelled field: `getByLabel` over `getByRole('textbox')`

An input with an associated label is located with `getByLabel('Email')`. It reads as the user sees the field and survives a role change (a `textbox` that becomes a `combobox`). Reserve `getByRole('textbox', { name })` for inputs without a label.

## Exact and scoped matches

- Text that could match more than one element: `{ exact: true }`, or a more specific role.
- Several similar elements under one container: scope the search, `page.getByRole('form', { name: 'Login' }).getByRole('button', { name: 'Save' })`.

## CSS exception

A CSS locator is not a sixth tier. It ships only when all three hold:

1. The snapshot shows no role, label, placeholder, text or test id for the element.
2. You asked for a `data-test` id and the human confirmed the app cannot take one (third-party widget, markup that cannot be changed, no access to the app's code).
3. The line above the locator disables the lint rule and states why nothing semantic fits:

```typescript
get orderRows(): Locator {
    // eslint-disable-next-line playwright/no-raw-locators -- vendor grid: rows have no role, name or test id
    return this.page
        .getByRole('region', { name: 'Orders' })
        .locator('[data-row-id]');
}
```

- Scope it under a semantic parent, as above.
- A stable attribute (`[data-row-id]`, `[name="q"]`) over an id, an id over a class; never a generated or utility class (`.css-1x2y3z`, `.mt-4`).
- `npm run lint` fails a raw `locator()` without the disable line. XPath stays forbidden with or without it.

## Symptoms

| Symptom                                                 | Cause                                                | Fix                                                                                                                                                             |
| ------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Strict-mode violation, locator matched several elements | Shared accessible name or text                       | `{ exact: true }`, a narrower role, or scope to the parent                                                                                                      |
| Element "stale" after navigation                        | Misdiagnosis: a `Locator` re-queries on every action | The element is not there yet (`await expect(locator).toBeVisible()`), the DOM changed (re-snapshot, update the locator), or it sits in a frame (`frameLocator`) |
| No accessible name (`<button><svg/></button>`)          | Markup without a label or `aria-label`               | Re-check the snapshot for an `aria-label`; otherwise ask for a `data-test` id and use `getByTestId`. The app cannot take one: the CSS exception above           |
