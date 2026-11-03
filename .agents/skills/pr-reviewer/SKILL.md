---
name: pr-reviewer
description: Use when the user names a branch with any review intent ("review PR for branch X", "is branch Y good to merge", "check the changes on Z"). Not for the uncommitted working tree, or for authoring new tests or page objects (see `ai-native-workflow`).
---

# PR Reviewer

## Critical

- **Read-only until the report is delivered.** Fixes only when the user asks after reading it; a commit only on explicit approval.
- **Always the three-dot diff against the remote base** (`git diff "$BASE"...HEAD` with `BASE=origin/<name>`); a two-dot diff reviews commits the author never wrote.
- **Route every changed path to its skills and read them** before judging; the Constitution applies everywhere.
- **Run the checks, do not only read**: `scripts/verify-changed.sh` and the affected specs.
- **The Constitution checklist is a gate before the report**: `scripts/scan-constitution.sh` in this skill's directory, then `references/constitution-checklist.md` with `file:line` evidence; every ❌ is a finding.
- **Every finding is tied to a rule, a bug or a missing case**; a style opinion without a rule is noise.
- **Env failures are not branch failures.** A run that dies on a missing env var or token is reported as such; never invent or stub a credential.
- **A schema loosened to swallow a runtime surprise is a must-fix finding** (`z.strictObject` → `z.object`, `.optional()`, `.nullable()`, `.catchall()`, a widened validator); the sanctioned fix is `test.skip` + `// FIXME`. Never `--approve` or `--request-changes` on the user's behalf.

## Procedure

1. `scripts/checkout-branch.sh <branch> [base]` resolves the base, refuses a dirty tree, fetches and switches, prints `BASE` and `ORIGINAL_REF`; a `STOP` line means ask the user.
2. Read the whole diff first: `git diff "$BASE"...HEAD --stat`, then `git diff "$BASE"...HEAD`.
3. Route with the table and read each listed skill; a path outside the table takes the closest indexed skill.

    | Changed path                                               | Read                                              |
    | ---------------------------------------------------------- | ------------------------------------------------- |
    | `tests/**/api/**`                                          | `api-testing`, `test-standards`, `type-safety`    |
    | `tests/**/e2e/**`, `tests/**/functional/**`                | `test-standards`, `page-objects`, `fixtures`      |
    | `tests/**/*.setup.ts`                                      | `helpers`, `fixtures`, `test-standards`           |
    | `pages/**`                                                 | `page-objects`, `selectors`, `playwright-cli`     |
    | `fixtures/api/schemas/**`                                  | `type-safety`, `api-testing`                      |
    | `fixtures/**`                                              | `fixtures`, `helpers`                             |
    | `test-data/factories/**`                                   | `data-strategy`, `type-safety`                    |
    | `test-data/static/**`                                      | `data-strategy`, `refactor-values`, `type-safety` |
    | `enums/**`, new members                                    | `enums`                                           |
    | `enums/**`, `test-data/static/**`, changed existing values | `refactor-values`                                 |
    | `config/**`                                                | `config`                                          |
    | `helpers/**`                                               | `helpers`                                         |
    | any `**/*.ts`                                              | `type-safety`                                     |

4. `scripts/verify-changed.sh "$BASE"` (eslint, prettier, tsc on the changed files), then the affected specs per `references/verification.md`.
5. Review the diff against the routed skills: the Constitution rows for the area, contract fidelity, consistency with the nearest sibling file, real bugs (wrong assertion, `.find()` on a possibly empty response, copy-paste leftovers), coverage gaps, scope creep.
6. Run the scan script, then walk the checklist against the diff; ➖ only when the branch does not touch the area, "could not evaluate" recorded as such, never as ✅.
7. Report in chat with `assets/report-template.md` and the confidence rubric in `references/reporting.md`; post to the PR only when asked. Then `git switch "$ORIGINAL_REF"`.
8. Offer fixes ("Want me to implement any of these findings?"); apply only the chosen ones per the routed skills, re-run step 4, then ask before committing (Conventional Commit subject, co-author trailer).

## References

- `references/constitution-checklist.md`: step 6, the 30-row gate.
- `references/verification.md`: step 4, the tsc detour, running the affected specs, the env limit.
- `references/reporting.md`: step 7, the confidence rubric and posting to GitHub.
- `assets/report-template.md`: step 7, the report shape.
- `assets/review-prompt.md`: a paste-ready invocation for the user.
- `scripts/checkout-branch.sh`, `scripts/verify-changed.sh`, `scripts/scan-constitution.sh`: steps 1, 4 and 6.
