# Feedback selectors

A page object that submits a form or runs a CRUD action carries a locator for each outcome the app renders, so a test can assert the result instead of the absence of an error.

| Feedback type         | When it appears                             | Locator                                                                        |
| --------------------- | ------------------------------------------- | ------------------------------------------------------------------------------ |
| Success message       | After a successful create, update or delete | `getByText(Messages.PROFILE_SAVED)` or `getByRole('alert')`                    |
| Error message         | After a failed submit or a server error     | `getByText(Messages.SAVE_FAILED)` or `getByRole('alert')`                      |
| Field validation      | On blur or submit with invalid input        | `getByText(Messages.EMAIL_REQUIRED)`, scoped to the form when the text repeats |
| Toast or notification | Briefly after any operation                 | `getByRole('status')`, or `getByText` on the toast content                     |
| Loading state         | During an async operation                   | `getByRole('progressbar')` or `getByText(Messages.LOADING)`                    |
| Empty state           | A list or table with no rows                | `getByText(Messages.NO_ITEMS)` or the empty-state heading                      |

The `Messages.*` names are illustrative; each real member is added to `enums/{area}/*` with the text captured in exploration. The live instance is `AppPage` in `pages/app/app.page.ts` (`errorMessage`, `emailRequiredError`, `passwordRequiredError`, `emailFormatError`), with the success signal being the visible `username`.

A test asserts the outcome through the locator:

```typescript
await profilePage.saveName(user.name);
await expect(profilePage.savedMessage).toBeVisible();
```
