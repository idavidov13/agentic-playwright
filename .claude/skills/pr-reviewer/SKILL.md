---
name: pr-reviewer
description: Reviews a Git branch as a pull request against the base branch (auto-resolved from origin/HEAD — usually main or master) using this repo's own rules — the CLAUDE.md constitution and the .claude/skills/ that apply to the changed files. Fetches the branch, switches to it, diffs it against the merge-base, routes the changed files to every applicable skill, verifies (eslint + prettier + tsc, and attempts the affected tests), then reports tiered findings with a confidence score. After reporting it OPTIONALLY offers to implement fixes for the findings, and only if fixes are applied does it ask permission to commit. Use this whenever the user names a branch alongside any review intent — "review PR for branch X", "PR review on aex-1234-foo against master", "review the diffs on branch Y", "check / audit the changes on branch Z", "is branch W good to merge". Use it even when the user says "PR" without the word "review", or "review" without "PR", as long as a branch is in play. Do NOT use this for reviewing the current uncommitted working-tree diff (that is /code-review's job) or for authoring brand-new tests/page objects from scratch (route to common-tasks / api-testing / page-objects instead).
author: Ivan Davidov
---

# PR Reviewer

Review a branch the way a careful human reviewer on this team would: against **this repo's own contract**, not generic best practice. The contract is `CLAUDE.md` (the Constitution — MUST / SHOULD / WON'T tables) plus the specialized `.claude/skills/` that govern whatever the branch actually touched. A finding only counts if you can tie it to a concrete rule, a real bug, or a coverage gap — opinion without a rule behind it is noise.

The deliverable is a **report**, not a code change. Fixing is a separate, opt-in step the user has to ask for after seeing the findings.

---

## Input

The user gives a **branch name** and a review ask. The base branch is **auto-resolved** in Phase 1 — the remote's default head (`origin/HEAD`), which is `main` in some repos and `master` in others — and falls back to `master` only if that can't be read. Accept an override if the user names a different base. Nothing else is required; everything you need is in the diff and the repo.

---

## Workflow

Run these phases in order. Phases 1–7 are the review and always run (Phase 6, the Constitution checklist, is a mandatory gate before the report). Phases 8–9 are gated and only run if the user opts in.

### Phase 1 — Fetch & switch

```bash
# Resolve the base branch (don't hardcode). Use the user's override if given,
# else the remote's default head, else master.
BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
BASE=${BASE:-master}

git fetch origin "<branch>" "$BASE"
git switch "<branch>"      # or: git checkout <branch>
```

- **Dirty working tree** — if `git status --porcelain` is non-empty, **stop and ask** before switching. Offer to `git stash` and restore afterward; never switch over uncommitted work silently.
- **Missing branch** — if the branch isn't on `origin`, report that and stop.
- Everywhere below, `master` is shorthand for the resolved `$BASE`.

### Phase 2 — Diff against the merge-base (THREE-DOT, MANDATORY)

Always diff with **three dots**. This is not a preference — a two-dot diff is a defect in the review itself:

```bash
git diff master...HEAD --stat      # overview
git diff master...HEAD             # full diff
```

- `master...HEAD` (three-dot) diffs against the **merge-base** — the point where the branch forked — so you see exactly and only what the branch authored.
- `master..HEAD` (two-dot) drags in every commit that landed on `master` _after_ the branch forked and presents them as the branch's work. Reviewing those produces **false findings against code the author never wrote** — the single most common way a PR review goes wrong here.

**Never** use two-dot. If you catch yourself about to flag something, confirm its hunk appears in the three-dot diff before it becomes a finding. Read the whole diff before forming any opinion.

### Phase 3 — Route to applicable skills

The changed file paths decide which rules apply. This is the heart of doing it _right_ — an API branch and a UI branch are judged by different skills. Map every changed path to its skills and **read those skill files** before reviewing. Always also hold the `CLAUDE.md` Constitution.

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

If the diff touches an area not in this table, fall back to the `CLAUDE.md` skills index and pick the closest match. When unsure which skill owns a concern, load `ai-native-workflow` — it is the routing authority.

### Phase 4 — Verify (run the checks, don't just read)

Static reading misses real failures. Run the tooling on the **changed files only**. First capture the changed `.ts` paths once (drop deleted files), then reuse the list:

```bash
# Changed TypeScript files vs the merge-base, deletions excluded.
CHANGED=$(git diff master...HEAD --name-only --diff-filter=d -- '*.ts')

# Lint + format only those files. Guard the empty case explicitly — don't rely
# on `xargs -r` (GNU-only; BSD/macOS xargs has no -r and an empty pipe would
# otherwise run the tool against the whole repo).
[ -n "$CHANGED" ] && echo "$CHANGED" | xargs npx eslint
[ -n "$CHANGED" ] && echo "$CHANGED" | xargs npx prettier --check
```

**Typecheck — narrowed to the changed files.** `tsc --noEmit` always type-checks the whole project (it follows imports and honours the project's `tsconfig` — passing single files with `tsc --noEmit foo.ts` _ignores_ the tsconfig and gives wrong results, so don't). Run the full check, then filter its output to the changed paths with a fixed-string match against the captured list:

```bash
npx tsc --noEmit 2>&1 | grep -F -f <(echo "$CHANGED") \
  && echo ">>> tsc errors ABOVE are in changed files — branch's responsibility" \
  || echo "no tsc errors in changed files"
```

> **Why this matters — do not skip.** This repo ships **known pre-existing** tsc errors in unrelated files (e.g. `custodialFees.spec.ts`, `login-fixture.ts`, `expectResponseManageCustomerAccount.ts`). A wall of red from a bare `tsc --noEmit` does **not** mean the branch is broken. Only errors whose path is in `$CHANGED` are the branch's fault — everything else is repo background noise and must not become a finding. `grep -F -f` matches the exact changed paths because both `tsc` and `git diff --name-only` print repo-relative paths.

Then **attempt** the affected tests. **Don't assume the project name** — it varies per repo and per area. Read the real project names from the config first, then match the changed spec's area to one:

```bash
# Discover the actual project names this repo defines.
grep -nE "name:\s*['\"]" playwright.config.* 2>/dev/null
# or, if config is split:
grep -rnE "name:\s*['\"]" --include="*.config.ts" . | grep -v node_modules

# Then run the changed spec under the project whose name matches its area.
npx playwright test <changed spec path> --project <project-name>
```

> The naming scheme is **repo-specific** (often `<area>-<browser>`, e.g. `front-chromium`, but not guaranteed). Derive `<area>` from the spec path `tests/<area>/...`, then pick the config project whose name contains that area. A bare area word or the spec path alone usually won't select a project. Setup projects (commonly `<area>-setup`) run automatically as dependencies. If no project matches, run without `--project` and note it in the report.

**Missing env ≠ branch defect.** API / wallet / back specs read runtime tokens (`USER_ACCESS_TOKEN_WALLET`, `PUBLIC_GATEWAY_URL`, etc.) that a `*.setup.ts` mints from real credentials. With no env file those vars are undefined and the run dies at auth/setup. That is an **environment limitation, not a branch defect** — report it verbatim as _"could not run — missing env tokens (`<var>`); run manually before merge"_ and move on. **Never** invent, hardcode, or stub a token to force a green run.

### Phase 5 — Review against the rules

> **Large diffs — fan out.** If the diff spans many files (rough rule: >~15 changed files or >~1500 added lines), don't try to hold it all in one pass — reviewing tired produces missed findings. Group the changed files by area and review each group against its routed skills as a separate unit (a `Workflow` with one reviewer per group, then merge + dedupe findings, is a good fit). Small diffs review fine in a single pass.

With the routed skills + Constitution in hand, walk the diff and check, at minimum:

- **MUST rules** from `CLAUDE.md` for the touched area — e.g. for API specs: `expect(Schema.parse(body)).toBeTruthy()` exactly; `z.strictObject()` not `z.object()`; **2+ API calls each in its own `test.step()`**; one tag per test; URLs/paths/messages from `config`/`enums` not hardcoded; state-mutating tests have cleanup hooks.
- **WON'T rules** — no `any`, no XPath, no `waitForTimeout()`, no hardcoded secrets/content, no loose schemas, no tags on `describe`, no silent coverage drops (every documented status code has a test — passing, failing, or `test.skip` + `// FIXME`).
- **Contract fidelity (STRICT).** Schemas must mirror the documented OpenAPI/Swagger contract — `z.strictObject`, exact field nullability, correct top-level validators. When the live API disagrees with the documented contract, the API is the bug, **never the schema**. Flag — as a 🔴 Must-fix — any of these schema-loosening moves, even if they make a test pass: relaxing `z.strictObject` → `z.object`; adding `.optional()`/`.nullable()`/`.passthrough()`/`.catchall()` or widening a type purely to absorb an unexpected runtime value; deleting a field the contract documents; replacing a precise validator (`z.uuid`, `z.iso.datetime`, `z.int`) with a looser one. The sanctioned response to a real mismatch is `test.skip` + `// FIXME: <ticket>` documenting the discrepancy — the schema stays faithful to the contract. A loosened schema is worse than a skipped test because it permanently hides the drift.
- **Consistency with siblings** — compare against the nearest existing file of the same kind (the sibling controller spec, the neighbouring page object). Divergence from an established pattern is a finding even when no rule names it.
- **Real bugs** — logic errors, wrong assertions, fragile data assumptions (e.g. `.find()` on a possibly-empty env response), off-by-one, copy-paste leftovers (stale qase IDs, wrong endpoint).
- **Coverage gaps** — status codes / fields / negative cases present in siblings but missing here.
- **Scope creep** — changes unrelated to the branch's ticket; flag as noise even if harmless.

### Phase 6 — Constitution checklist (MANDATORY GATE)

**Do not write the report until this is done.** This gate is the most load-bearing step — it converts "I read the diff and it felt fine" into an auditable verdict against every floor rule, and it is where reviews that skip straight to vibes go wrong.

**Run the mechanical scan first**, then do the judgment items by hand:

```bash
.claude/skills/pr-reviewer/scripts/scan-constitution.sh "$BASE"
```

The script greps the changed files for the deterministically-detectable violations (`any`, `z.object(`, `waitForTimeout`, XPath, `@playwright/test` import in specs, manual page-object `new`, `@functional`, tags on `describe`, `.json` under `test-data/static`, magic-number timeouts, hardcoded URLs) and lists every `Schema.parse()` call site for you to confirm. It maps each check to a checklist row by `[#]`. Use its ✅/❌ to fill those rows directly — it can't miss a hit the way a manual scan can, and it frees your attention for the judgment items.

Then read **`references/constitution-checklist.md`** and walk the remaining items against the three-dot diff — the ones a grep can't judge: coverage gaps, sibling divergence, schema-vs-contract fidelity, cleanup hooks, return-type completeness, feedback-message selectors. Record ✅ / ❌ / ➖ with `file:line` evidence for every applicable item. The routed skills from Phase 3 layer area-specific depth on top — the checklist is the non-negotiable baseline.

Rules:

- Mark ➖ **only** when the branch genuinely doesn't touch that area — never as a shortcut for "looks fine."
- Every ❌ becomes a finding in the report at the tier the checklist assigns.
- If an item can't be evaluated (e.g. tests unrunnable for missing env), record that explicitly — do not mark it ✅.
- The count of unresolved ❌ directly feeds the verdict and confidence score in Phase 7.

### Phase 7 — Report

Use the exact template in **`assets/report-template.md`**. Tiered (🔴 Must-fix / 🟠 Should-fix / 🟡 Minor), a ✅ Good section so the author knows what's right, an overall verdict, a **confidence score with rationale**, and an **open-questions-for-author** block for things you genuinely can't resolve from the repo (e.g. "is the wallet env guaranteed to seed a notice with a PDF?"). Every ❌ from the Phase 6 checklist must appear here. Confidence rubric is below.

**Default: report in chat.** Post to the GitHub PR only when the user asks (e.g. "review and comment on the PR", "post the findings", "--comment"). When they do:

```bash
# Find the PR for the branch (must exist; don't open one unasked).
gh pr view <branch> --json number,url -q '.number'
```

- **Summary review** — post the whole report as one PR review body:
  `gh pr review <number> --comment --body-file <report.md>`
- **Inline findings** — anchor each 🔴/🟠 finding to its `file:line` as a review comment. Keep one comment per finding, one line each: location · problem · fix. Post them in a single review via the GitHub API (`commit_id` must be the branch's current HEAD SHA):

    ```bash
    HEAD_SHA=$(git rev-parse HEAD)
    gh api -X POST "repos/{owner}/{repo}/pulls/<number>/reviews" \
      -f commit_id="$HEAD_SHA" \
      -f event="COMMENT" \
      -f body="<short summary>" \
      -F 'comments[][path]=path/to/file.ts' \
      -F 'comments[][line]=42' \
      -F 'comments[][body]=🔴 problem · fix'
    ```

    Repeat the `comments[][...]` triple per finding. `line` is the line in the file's new version; use `side=RIGHT` (default) for added/changed lines.

- Never `--approve` or `--request-changes` on the user's behalf — use `--comment` only; the human owns the verdict.
- If no PR exists for the branch, say so and ask whether to open one (`gh pr create`) — don't open it unprompted.

**Stop here.** This is the primary deliverable. Do not modify any file.

### Phase 8 — OPTIONAL: offer to implement fixes

After the report, offer: _"Want me to implement any of these findings?"_ The user picks which (all, must-fix only, a specific subset). Only then do you edit files. Apply fixes the way the routed skills prescribe; match sibling patterns; keep changes minimal and on-scope. Re-run Phase 4 verification on what you changed.

### Phase 9 — OPTIONAL: ask to commit

**Only if Phase 8 actually changed files**, and only after re-verification passes, ask permission to commit. Never commit without explicit approval. Use a Conventional Commit subject referencing the ticket; end the commit message with the repo's required co-author trailer.

---

## Confidence rubric

State a 1–10 score with a one-line rationale and the unknowns that cap it.

- **9–10** — diff fully read, all applicable skills routed, lint/tsc run clean on changed files, findings each tied to a rule/bug; only trivia left uncertain.
- **6–8** — review solid but something couldn't be confirmed (tests unrunnable for lack of env, an OpenAPI contract you couldn't see, a data assumption you couldn't verify).
- **≤5** — couldn't read the full diff, couldn't route the right skills, or the branch depends on context you don't have. Say what's missing instead of guessing.

Be honest about what you couldn't verify — a capped score with a clear reason is more useful than false certainty.

---

## Guardrails

- **Read-only until Phase 7 is approved.** The review never edits files. If the user only asked to "review", they get a report and nothing else.
- **Three-dot diff always.** Reviewing master's own commits is the most common false-finding source.
- **Every finding needs a hook** — a rule, a bug, or a missing case. No rule-less style opinions.
- **Runtime ≠ contract (hard line).** API behaviour that disagrees with the documented spec is a bug to _report_ via `test.skip` + `// FIXME: <ticket>`, **never** a schema to _relax_. Any schema-loosening introduced to swallow a runtime surprise is itself a 🔴 Must-fix finding — see the Contract-fidelity bullet in Phase 5.
- **Env failures aren't branch failures.** Distinguish "the branch is wrong" from "I lack the tokens/URL to run it".
- **Don't trust the diff's own claims.** If a comment or test name says one thing and the code does another, that gap is itself a finding.

---

## Quick prompt

A ready-to-paste invocation lives in **`assets/review-prompt.md`** — hand it to the user when they ask "how do I kick this off".
