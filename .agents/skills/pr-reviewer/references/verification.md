# Verification

Step 4 of `pr-reviewer`. The branch is checked out at its origin tip and the tree is clean (step 1 refuses otherwise).

## Static checks

`scripts/verify-changed.sh "$BASE"` lists the TypeScript files of the three-dot diff (deletions and the deliberate violations under `lint-fixtures/` excluded), runs `eslint --max-warnings 0` and `prettier --check` on them, then runs `tsc --noEmit` on the whole project (single-file `tsc` ignores `tsconfig.json`) and prints the errors inside the changed files separately from the rest. Exit 1 means at least one check failed on a changed file.

Errors outside the changed files are not discarded: a changed type can break an unchanged consumer. Decide which they are by checking the base:

```bash
git switch --detach "$BASE" && npx tsc --noEmit; git switch -
```

An error that also exists on the base is pre-existing and is noted, not charged to the branch; anything else is the branch's responsibility.

## Affected specs

Project names are repo-specific; read them before running anything:

```bash
grep -nE "name:\s*['\"]" playwright.config.ts
```

This scaffold defines `setup-api`, `setup-ui`, `api` and `chromium`: API specs run under `api` (depends on `setup-api`), UI specs under `chromium` (depends on both setup projects). Run each changed spec by path:

```bash
npx playwright test <changed spec> --project <name>
```

No matching project: run without `--project` and say so in the report.

## Env limit

Specs read `APP_URL`, `API_URL`, `APP_EMAIL` and `APP_PASSWORD` (declared in `env/.env.example`) and the token the `setup-api` project mints. Without them the run dies at setup. That is an environment limitation, not a branch defect: report it verbatim as "could not run — missing env vars (`<var>`); run manually before merge" and move on. Never invent, hardcode or stub a credential to force a green run.

## Large diffs

Over about 15 changed files or 1,500 added lines, group the files by area and review each group against its routed skills as a separate pass, then merge and dedupe the findings.
