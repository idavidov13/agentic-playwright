# PR Review — `<branch>` vs `<base>`

<one-line summary: N commits, what the branch does, how it compares to siblings>

## 🔴 Must-fix

<Constitution MUST/WON'T violations and real bugs. Each row: file:line — problem — the rule it breaks — the fix. Omit the section if empty and say so.>

| #   | Issue | Location    | Rule / why                          | Fix |
| --- | ----- | ----------- | ----------------------------------- | --- |
| 1   | ...   | `path:line` | `.cursor/rules/rules.mdc MUST: ...` | ... |

## 🟠 Should-fix

<Recommended changes: SHOULD rules, fragile-but-not-broken patterns, sibling divergence. Same columns.>

## 🟡 Minor

<Typos, scope creep, cosmetic, consistency nits.>

## ✅ Good

<What the branch got right — so the author knows the strong parts and they survive any fixing pass.>

## Verification

- ESLint: <pass / fail + summary>
- Prettier: <pass / fail>
- tsc (changed files only): <clean / errors — and note any pre-existing repo-wide errors ignored>
- Tests: <ran & result / "could not run — missing env tokens; run manually before merge">
- Constitution checklist: <N ✅ / M ❌ / K ➖ — every ❌ is listed above at its tier; note any item that couldn't be evaluated>

## Verdict

<Approve / Approve-after-must-fix / Request-changes> — **Confidence: X/10.** <one-line rationale + what capped it>

## Open questions for author

<Things you genuinely can't resolve from the repo and that change the findings. e.g. "Is the wallet test env guaranteed to seed ≥1 notice with a PDF? That decides whether the dynamic .find() is safe.">
