---
name: refactor-values
description: Use before changing an existing enum member's value or key under enums/** or editing an existing value under test-data/static/**. Not for adding a new enum or member (see `enums`) or a new static set (see `data-strategy`).
---

# Refactor Values

## Critical

- **Before any edit, find all consumers.** Search the enum key (`Messages.LOGIN_ERROR`) and the raw string value (`'Invalid email or password'`) across the whole repository; a consumer that bypassed the enum does not follow it.
- **Every consumer changes in the same commit** as the enum member or static entry; no state where the value moved and a consumer still holds the old one.
- **Never loosen `z.literal` or `z.enum` to a wider type** to make a changed value pass; move the literal, or list the valid values.

    ```ts
    role: z.literal('administrator'), // correct: the literal follows the value
    ```

    ```ts
    role: z.string(), // wrong: hides the next drift
    ```

- **`npx tsc --noEmit`, `npx eslint .` and the affected tests pass before the refactor is done.**
- **No blind find-and-replace.** Inspect every match; hits include `.md` docs and skills, comments and case variants.

## Procedure

1. Search both forms and list every hit (`rg` or `grep -rn`; skip `.json` reports):

    ```bash
    rg -n "Messages.LOGIN_ERROR|Invalid email or password" --glob '!*.json' .
    ```

2. Categorise each hit with `references/impact-tables.md`; the files that change are the proposal's scope.
3. Change the source (enum member or `as const` entry) and every listed consumer in one pass; a UI message is captured from the live app with `playwright-cli` first (`enums`).
4. Run `npx tsc --noEmit`, `npx eslint .`, then the affected spec files by path (`--grep` matches tags and titles, not file names); red → `debugging`.

## References

- `references/impact-tables.md`: step 2, the consumer table per change type and the stale-consumer patterns.
