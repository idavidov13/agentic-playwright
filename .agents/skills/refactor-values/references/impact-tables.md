# Impact tables

Step 2 of `refactor-values`. Pick the table for the change; every row with a hit is a file in the proposal's scope.

## Enum value change (what the member resolves to)

| Consumer                                                                           | Effect of the change                | Action                         |
| ---------------------------------------------------------------------------------- | ----------------------------------- | ------------------------------ |
| Test asserting the old raw string (`toHaveText('...')`, `getByText('...')`)        | fails; the string bypassed the enum | replace with the enum member   |
| Page object or test using `getByText(Messages.X)`                                  | follows the enum                    | none                           |
| Zod schema with `z.literal('old')` or `z.enum([..., 'old'])`                       | rejects the new value               | update the literal or the list |
| `apiRequest` call with a hardcoded path                                            | calls the old URL                   | replace with `ApiEndpoints.X`  |
| Static entry under `test-data/static/` holding the old string as an expected value | data mismatch                       | update the `as const` entry    |
| Another enum member derived from this value                                        | indirect breakage                   | audit it                       |
| `.md` docs and skills, comments                                                    | stale text                          | update                         |

## Enum key rename (`LOGIN_ERROR` → `AUTH_FAILURE`)

| Consumer                        | Effect of the change     | Action                 |
| ------------------------------- | ------------------------ | ---------------------- |
| Every file using the old key    | `npx tsc --noEmit` error | rename in every file   |
| Barrel or re-export file        | may pass at runtime      | check `index.ts` files |
| `.md` docs and skills, comments | stale name               | update                 |

## Static value change (an existing entry under `test-data/static/`)

| Consumer                                         | Effect of the change                 | Action                                             |
| ------------------------------------------------ | ------------------------------------ | -------------------------------------------------- |
| Data-driven loop importing the `as const` export | the assertion uses the changed value | confirm the case still tests the intended boundary |
| Test asserting the old value directly            | fails                                | update the expected value                          |
| Enum member mirroring the string                 | out of sync                          | update the member                                  |

## Stale-consumer patterns

Value changed, a consumer still holds the old string:

```ts
((LOGIN_ERROR = 'Incorrect credentials. Please try again.'), // updated
    await expect(page.getByText('Invalid email or password')).toBeVisible()); // stale
```

Key renamed, one file missed (`npx tsc --noEmit` reports it):

```ts
Messages.AUTH_FAILURE; // file A, updated
Messages.LOGIN_ERROR; // file B: Property 'LOGIN_ERROR' does not exist
```

Static value changed, an assertion not updated:

```ts
password: ('UpdatedWrongPassword!', // test-data/static/app/invalidCredentials.ts
    expect(response.password).toBe('WrongPassword123!')); // stale
```
