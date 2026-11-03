---
name: common-tasks
description: Use when the user wants a prompt template ("give me a prompt for X", "how do I add a page object, test, schema, factory, fixture or component") or the post-codegen verification checklist. Not for building the artifact directly (see `ai-native-workflow`, which routes that to the leaf skill).
---

# Common Tasks

## Critical

- **Resolve `{area}` before filling any template.** Run the row's `ls` and substitute the real folder name; never guess it.
- **Templates are starters.** The leaf skill in the row owns the rules; load it and follow it end to end instead of restating its rules in the prompt.
- **Walk `references/verification-checklist.md` after generating**, also when routing skipped this skill and went straight to a leaf skill.

## Procedure

1. Match the request to one row and run its `ls`:

    | Artifact                            | Template                               | Leaf skill                   | `ls` first                                           |
    | ----------------------------------- | -------------------------------------- | ---------------------------- | ---------------------------------------------------- |
    | Page object                         | `references/templates/page-objects.md` | `page-objects`               | `ls pages/`                                          |
    | Component                           | `references/templates/components.md`   | `page-objects`               | none                                                 |
    | Functional, E2E or data-driven test | `references/templates/tests.md`        | `test-standards`             | `ls tests/`, `ls test-data/static/`                  |
    | API test                            | `references/templates/tests.md`        | `api-testing`                | `ls tests/`, `ls fixtures/api/schemas/`, `ls enums/` |
    | Zod schema                          | `references/templates/api-schemas.md`  | `api-testing`, `type-safety` | `ls fixtures/api/schemas/`                           |
    | Factory or static data              | `references/templates/data.md`         | `data-strategy`              | `ls test-data/factories/`, `ls test-data/static/`    |
    | Fixture                             | `references/templates/fixtures.md`     | `fixtures`, `helpers`        | none                                                 |

2. Open the template, copy the block, replace every `[PLACEHOLDER]` and `{area}`; none may remain.
3. Load the leaf skill; generate per its Critical block and Procedure.
4. Walk the checklist, then run `npx playwright test <file>`; red → `debugging`.

## References

- `references/verification-checklist.md`: after every generated artifact.
- `references/templates/page-objects.md`: page object with or without exploration, add locators, add an action method.
- `references/templates/components.md`: reusable component.
- `references/templates/tests.md`: functional, E2E, data-driven and API tests.
- `references/templates/api-schemas.md`: schema from the documentation, fallback capture, add fields.
- `references/templates/data.md`: factory, static data set.
- `references/templates/fixtures.md`: page-object fixture, helper fixture, fixture category.
