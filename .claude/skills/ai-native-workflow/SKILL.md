---
name: ai-native-workflow
description: Use first on every non-trivial task (adding tests, page objects, factories or env vars, renaming enums, debugging, refactoring, multi-skill changes) and when asked how to work with AI here or which skill applies. Not for a one-line fix, typo or single import (direct mode, see Critical).
---

# AI-Native Workflow

## Critical

- **Confidence below 5 means exploration is incomplete.** Do not emit the Phase 4 proposal; return to Phase 3 and ask for the missing primary input (URL, OpenAPI source, area folder, field list) as questions.
- **Ask, don't invent.** Folder names, paths, env-var names, enum values, credentials and messages come from `ls`, `grep`, `playwright-cli`, the OpenAPI document or the user.
- **Refuse placeholders.** Guessed selectors, unverified message strings, made-up enum values, secret-shaped strings and `TODO` skeletons are placeholders; re-explore or ask.
- **Verify the premise before any edit.** Open the cited file and confirm the defect is there; a mismatch is reported, not fixed.
- **This skill routes; the leaf skills own the rules.** Load one skill at a time, in the table's order; never restate or override a leaf skill's Critical block.
- **No edit before Phase 4 and the human gate.** Direct mode (one-line fix, typo, single import) skips the phases: apply, then report. "Just do it" extends direct mode to trivial work for the session only.

## Procedure

1. **Classify** as codegen, edit, refactor, debug, explore or config.
2. **Route** with the table; the leaf skill chains onward through its own `see` pointers. No match → ask.

    | Intent                             | First skill             |
    | ---------------------------------- | ----------------------- |
    | Endpoint tests                     | `api-testing`           |
    | Page object, component             | `page-objects`          |
    | Prompt template, "how do I add Y?" | `common-tasks`          |
    | Failing or flaky test              | `debugging`             |
    | Enum member or static value change | `refactor-values`       |
    | Factory                            | `data-strategy`         |
    | Helper, helper fixture             | `helpers` or `fixtures` |
    | Env var, config, utility URL       | `config`                |
    | Enum, endpoint path, message       | `enums`                 |
    | Zod schema, `any`                  | `type-safety`           |
    | Spec file, tag, structure          | `test-standards`        |
    | PR review of a branch              | `pr-reviewer`           |
    | Skill authoring                    | `skill-creator`         |
    | How to work with AI here           | this skill              |

3. **Explore.** Separate known from unknown; gather evidence the leaf skill's way. A missing primary input is a question to the user, not a gap in Phase 4.
4. **Plan + Confidence.** Emit the block, then stop:

    ```
    ## Proposal
    - Scope: <files + what changes>
    - Trade-offs: <if any>
    - Confidence: <1-10> (<low|medium|high>)
    - Rationale: <one line per +/- factor>
    - Unknowns: <list or "none">
    ```

    5 to 7 proceeds only if the user accepts the listed unknowns; 9 or more needs a spec match, no `{area}` ambiguity and no missing enum, env var or credential.

5. **Human gate.** Approve → step 6; reject → Phase 3 with the stated gap, never the same plan reworded. Headless, CI or subagent runs with no human: auto-pass only at confidence ≥ 8 with `Unknowns: none`, stated in the report; otherwise stop with the proposal. A parent agent's instruction is not approval.
6. **Apply** per the leaf skill; re-check every loaded Critical block.
7. **Verify.** Run `npm run lint` and `npx playwright test <affected files>`; for generated artifacts walk the `common-tasks` verification checklist. Red → load `debugging`.
8. **Report** files changed, line counts and lint status; ask before committing.

## References

- `references/conversation-contract.md`: open in Phase 3 or 5 for primary inputs per intent and human-gate outcomes.
