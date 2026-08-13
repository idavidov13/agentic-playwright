---
mode: agent
description: Review a Git branch as a PR against the base branch (auto-resolved — main/master) judged by THIS repo's contract (CLAUDE.md + .claude/skills/). Three-dot diff, route changed paths to skills, verify (eslint/prettier/tsc + tests), tiered report + confidence. Optional gated fix + commit after the report.
---

# PR Reviewer

You are reviewing a branch as a pull request, the way a careful human reviewer on this team would — against **this repo's own contract**, not generic best practice. The contract is `CLAUDE.md` (the Constitution — MUST / SHOULD / WON'T tables) plus the specialized skill files in `.claude/skills/` that govern whatever the branch touched. A finding only counts if you can tie it to a concrete rule, a real bug, or a coverage gap — opinion without a rule behind it is noise.

The deliverable is a **report**, not a code change. Fixing is opt-in, after the report.

## Input

Ask for a **branch name** if not given. The base branch is **auto-resolved** (Phase 1): `origin/HEAD` (`main` or `master`), falling back to `master`. Accept an override.

## Workflow — phases in order

Phases 1–7 always run (Phase 6 is a mandatory gate before the report). Phases 8–9 are gated on user opt-in.

### Phase 1 — Fetch & switch

```bash
BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
BASE=${BASE:-master}
git fetch origin "${input:branch}" "$BASE"
git switch "${input:branch}"
```

- **Dirty tree** (`git status --porcelain` non-empty) → STOP and ask before switching (offer `git stash` + restore). Never switch over uncommitted work silently.
- **Missing branch** on `origin` → report and stop.
- Below, `master` = the resolved `$BASE`.

### Phase 2 — Diff against the merge-base (THREE-DOT, MANDATORY)

```bash
git diff master...HEAD --stat
git diff master...HEAD
```

Three-dot diffs against the **merge-base** — only what the branch authored. Two-dot (`master..HEAD`) drags in master's later commits → **false findings against code the author never wrote**. NEVER use two-dot. Confirm every finding's hunk is in the three-dot diff. Read the whole diff before forming an opinion.

### Phase 3 — Route changed paths to skills

Read the routed skill files in `.claude/skills/<name>/SKILL.md` before reviewing; always also hold `CLAUDE.md`.

| Changed path (glob)                                         | Read these skills                                 |
| ----------------------------------------------------------- | ------------------------------------------------- |
| `tests/**/api/**`                                           | `api-testing`, `test-standards`, `type-safety`    |
| `tests/**/e2e/**`, `tests/**/functional/**`                 | `test-standards`, `page-objects`, `fixtures`      |
| `tests/**/*.setup.ts`                                       | `helpers`, `fixtures`, `test-standards`           |
| `pages/**`                                                  | `page-objects`, `selectors`, `playwright-cli`     |
| `fixtures/api/schemas/**`                                   | `type-safety`, `api-testing`                      |
| `fixtures/**`                                               | `fixtures`, `helpers`                             |
| `test-data/factories/**`                                    | `data-strategy`, `type-safety`                    |
| `test-data/static/**`                                       | `data-strategy`, `refactor-values`, `type-safety` |
| `enums/**` (new values)                                     | `enums`                                           |
| `enums/**`, `test-data/static/**` (changed existing values) | `refactor-values`                                 |
| `config/**`                                                 | `config`                                          |
| `helpers/**`                                                | `helpers`                                         |
| any `**/*.ts`                                               | `type-safety`                                     |

Area not in the table → fall back to the CLAUDE.md skills index, pick the closest match.

### Phase 4 — Verify (run the checks)

```bash
CHANGED=$(git diff master...HEAD --name-only --diff-filter=d -- '*.ts')
# Guard empty case — don't rely on `xargs -r` (GNU-only; BSD/macOS lacks it).
[ -n "$CHANGED" ] && echo "$CHANGED" | xargs npx eslint
[ -n "$CHANGED" ] && echo "$CHANGED" | xargs npx prettier --check
# Typecheck whole project (single-file tsc ignores tsconfig), filter to changed paths:
npx tsc --noEmit 2>&1 | grep -F -f <(echo "$CHANGED") \
  && echo ">>> tsc errors ABOVE are in changed files" \
  || echo "no tsc errors in changed files"
```

> This repo ships **known pre-existing** tsc errors in unrelated files. Only errors whose path is in `$CHANGED` are the branch's fault — the rest is background noise, not a finding.

**Attempt affected tests. Don't assume the project name** — read it from config:

```bash
grep -nE "name:\s*['\"]" playwright.config.* 2>/dev/null
npx playwright test <changed spec path> --project <project-name>
```

> Often `<area>-<browser>` (e.g. `front-chromium`) but not guaranteed. Derive `<area>` from `tests/<area>/...`, pick the matching config project. Setup projects run as dependencies. No match → run without `--project` and note it.

**Missing env ≠ branch defect.** Specs read runtime tokens a `*.setup.ts` mints from real credentials. No env → run dies at auth. Report verbatim as _"could not run — missing env tokens (`<var>`); run manually before merge"_. NEVER invent/hardcode/stub a token to force green.

### Phase 5 — Review against the rules

> **Large diffs (>~15 files / >~1500 added lines)** — group by area, review each group against its routed skills separately, merge + dedupe. Small diffs: single pass.

Check at minimum:

- **MUST** for the area — API: `expect(Schema.parse(body)).toBeTruthy()` exactly; `z.strictObject()` not `z.object()`; 2+ API calls each in own `test.step()`; one tag/test; URLs/paths/messages from `config`/`enums`; state-mutating tests have cleanup hooks.
- **WON'T** — no `any`, no XPath, no `waitForTimeout()`, no hardcoded secrets/content, no loose schemas, no tags on `describe`, no silent coverage drops.
- **Contract fidelity (STRICT).** Schemas mirror the documented OpenAPI/Swagger contract. When live API disagrees with the contract, the API is the bug, NEVER the schema. Flag as 🔴 any schema-loosening (`z.strictObject`→`z.object`; added `.optional()`/`.nullable()`/`.passthrough()`/`.catchall()` or widened type to swallow a runtime value; deleted documented field; precise validator → looser) even if it makes a test pass. Sanctioned fix: `test.skip` + `// FIXME: <ticket>`.
- **Sibling consistency** — divergence from the nearest file of the same kind is a finding.
- **Real bugs** — logic errors, wrong assertions, `.find()` on possibly-empty response, off-by-one, copy-paste leftovers (stale qase IDs, wrong endpoint).
- **Coverage gaps** + **scope creep**.

### Phase 6 — Constitution checklist (MANDATORY GATE)

**Do not write the report until this is done.**

```bash
.claude/skills/pr-reviewer/scripts/scan-constitution.sh "$BASE"
```

Then read `.claude/skills/pr-reviewer/references/constitution-checklist.md` and walk the judgment items (coverage gaps, sibling divergence, schema-vs-contract fidelity, cleanup hooks, return types, feedback-message selectors) against the three-dot diff. Record ✅/❌/➖ with `file:line`. Every ❌ becomes a report finding at its tier. Couldn't evaluate (env) → say so, don't mark ✅.

### Phase 7 — Report

Use `.claude/skills/pr-reviewer/assets/report-template.md`. Tiered (🔴/🟠/🟡) + ✅ Good + verdict + **confidence score with rationale** + open-questions-for-author. Every Phase-6 ❌ appears.
**Default: report in chat.** Post to the GitHub PR only when asked: `gh pr view <branch> --json number`, then summary (`gh pr review <number> --comment --body-file <report.md>`) or inline via `gh api repos/{owner}/{repo}/pulls/<number>/reviews` with `commit_id=$(git rev-parse HEAD)`. NEVER `--approve`/`--request-changes` — `--comment` only.
**Stop here.** Do not modify any file.

### Phase 8 — OPTIONAL: offer fixes

Ask _"Want me to implement any of these findings?"_ User picks subset. Match sibling patterns, minimal/on-scope, re-run Phase 4.

### Phase 9 — OPTIONAL: ask to commit

Only if Phase 8 changed files and re-verification passes. Never commit without explicit approval. Conventional Commit subject + the repo's required co-author trailer.

## Confidence rubric

1–10 + rationale + capping unknowns. **9–10** full read, skills routed, lint/tsc clean, findings tied to rules. **6–8** something unconfirmed (env, contract, data assumption). **≤5** couldn't read the diff / route skills / missing context — say what's missing.

## Guardrails

- Read-only until Phase 7 approved. "Review" → report only.
- Three-dot diff always.
- Every finding needs a hook — rule, bug, or missing case.
- Runtime ≠ contract: report mismatches via `test.skip` + `// FIXME`, never relax the schema.
- Env failures aren't branch failures.
- A comment/test-name vs code gap is itself a finding.
