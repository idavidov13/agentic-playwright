# Changelog

All notable changes to Agentic Playwright are documented here. Entries are listed in reverse chronological order (newest first).

---

## v2.0.5 -- A Quarantine Convention for Flaky Tests -- 2026-11-17

### Rules layer

- **A flaky test that cannot be fixed now is quarantined, never silently skipped.** The agent investigates, then proposes a declaration-form `test.fixme` with a `quarantine` annotation (`owner=@handle; until=YYYY-MM-DD`); a human approves it and names the owner and the expiry. The procedure is `debugging` step 7 and `references/quarantine.md`.
- **ESLint enforces it for every spec under `tests/`** (`quarantine/annotation`, `lint/quarantine.mjs`): a skip passes only with the annotation or, for a contract mismatch, `test.skip` with `// FIXME: <ticket-url>` on the line above. A bare skip, the in-body forms (`test.skip(true, ...)`, `testInfo.skip()`) and `test.step.skip()` fail `npm run lint`. The expiry date is checked for form, not for having passed.

## v2.0.4 -- A Human-Set Test Scope, Worktree Setup for Orca -- 2026-11-14

### Rules layer

- **A human-set scope narrows the API coverage matrix.** A scenario list from the human, or a priority list with a cut-off, sets which rows are automated; each row they cut stays in the spec as a `// SCOPE` line naming the row and who cut it. A cut removes whole rows, the baseline rows included; the request-body rows (empty body, omitted field, wrong types) are cut together or not at all. With no list, or a priority list with no cut-off, the full matrix applies, and the agent never cuts a row on its own. **No Silent Coverage Drops** accepts the `// SCOPE` line, and row 10 of the `pr-reviewer` checklist and the Copilot review prompt (`.github/prompts/pr-reviewer.prompt.md`, Coverage gaps) with it.
- **The coverage matrix's status codes are the demo API's convention, its scenarios are the rule.** The expected status and error body come from the contract of the API under test. A baseline row the contract does not document is captured live, flagged and named in the plan, never assumed from the table; a live answer that looks wrong (a 5xx, a 2xx for invalid input) goes to the human. The verification checklist names those rows by scenario (missing auth, wrong role, unsupported method) instead of by code.
- **A `// SCOPE` line can name several rows.** Rows of one `test.describe` cut by the same source share one line, and `git grep -n '// SCOPE' -- tests/` lists every cut; when the cut-off moves, the human's new list replaces the lines. The reviewer copies say "the rows and who cut them".
- **A test built on an undocumented row is marked `// OBSERVED`.** A status or body the contract does not document, captured live, carries `// OBSERVED: <what the contract omits>, captured <YYYY-MM-DD>` above its test, so it reads as an observation, not an expectation. It is a third record next to `FIXME` (mismatch, skipped) and `SCOPE` (human cut). The `pr-reviewer` checklist row 10, the Copilot review prompt, the verification checklist and `AI-WORKFLOWS.md` check for it.
- **The README callout asks three review questions**: would the test fail if the feature broke, is every row left out recorded in a `// SCOPE` line, does it pass on a rerun.
- **Changing a rule includes the skill evals.** Step 4 of `CONTRIBUTING.md` "Changing a rule" names `.claude/skills/*/evals/evals.json`, whose expected behaviour can name a rule.
- **The `api-testing` contract-mismatch example is a complete test.** It moved from the skill's Critical section to `references/negative-testing.md` ("Contract mismatch"), which Critical now points to. It takes the `apiRequest` fixture, makes the call with its options in full, asserts the documented `status` and parses the body with the response schema; an empty `test.skip` fails `npm run lint`.
- **Only UI messages are sent to the `Messages` enums.** The `enums` table, the `data-strategy` rule and row 12 of the `pr-reviewer` checklist no longer name labels, headings or "UI strings" as enum values. A role name or a label sits inline in its page-object locator, as the `selectors` skill and the example page objects already show.

### Worktree setup (Orca)

- **`.claude/orca/orca-worktree-setup.sh` seeds a new git worktree** with the gitignored files that stay behind in the main checkout: `env/.env.dev` and `node_modules` (required; `node_modules` is a copy-on-write clone on APFS), every other `env/.env.*`, `.husky/_`, `.auth` and `.claude/settings.local.json` (optional). Wire it once as the Orca setup script, or run it by hand from any directory inside a worktree; `--dry-run` prints what would be copied, `--force` overwrites, except a path git tracks, which keeps its branch's version. Nothing else calls it, so without Orca the file is inert.
- **It verifies the install it copied**: `npm ls` against `package.json`, and `package-lock.json` against npm's record of what is installed, in both directions. A stale copy is reinstalled with `npm ci --prefer-offline` from the worktree's own lockfile. Without `npm` or `node` on `PATH` the check is skipped and the summary says the dependencies were not verified.
- **CI gates the script** (`.github/workflows/worktree-setup.yml`): ShellCheck reads it as POSIX sh, then it seeds a real worktree on Linux and macOS: a dry run that must write nothing, a real run, and a run from a subdirectory. The workflow is repo-only; `prepack.js` leaves it out of a scaffolded project.
- **`.playwright-cli/` is never copied**, so a worktree cannot inherit the exploration marker: Explore Before Generate holds in each worktree.
- The script ships in the template (a project scaffolded with `--no-claude` does not have it). `CLAUDE.md` gains one line that points a Claude Code session in an unseeded worktree to it.

### Docs

- The README states near the top what the scaffold guarantees (the form of a test) and what stays with human review (its value); the selector section says where UI text lives: a message found by text in the `Messages` enums, a role name or a label inline in the page object, none of it in a spec.
- README "Adapting the Scaffold" gains a step, "Match Your API's Error Conventions": change the shared error schemas and the matrix's Status column once for your API. `AI-WORKFLOWS.md` says the listed codes are the demo API's.
- `CONTRIBUTING.md` gains "Changing a rule", the order in which a rule's copies are edited, and asks for an issue before a large or design-level change.
- README "Git Worktrees (Orca)" and a troubleshooting entry describe the worktree setup; `CONTRIBUTING.md` points to it.

### Demo credentials

- **The demo user is `customer2@practicesoftwaretesting.com`.** The demo API locks `customer@practicesoftwaretesting.com` (423 on login), which failed the API auth setup in CI. The Playwright workflow and the initializer's demo `env/.env.dev` use `customer2`; the password stays `welcome01`.

---

## v2.0.3 -- Scope Qualifiers Restored, Test Isolation a MUST -- 2026-11-13

### Rules layer

- **Test Isolation is a MUST** (was SHOULD): the Constitution now has 15 MUST, 4 SHOULD and 17 WON'T rules. The `pr-reviewer` checklist gains a row for it (31 rows).
- **A CSS locator is a confirmed exception**, not a "last resort" tier: when no semantic locator fits, the agent asks for a test id first. A CSS locator ships only after the human confirms the app cannot take one, with the reason on the line in a `playwright/no-raw-locators` disable comment.
- **No documented API contract: the agent asks first.** Live capture starts only once the human confirms no document exists, and stays flagged.
- **An unreachable app stops the work** on a UI message enum; the `// FIXME: unverified` placeholder is gone.
- **Scope qualifiers restored on four Constitution rows**: Imports (spec files), No Manual Instantiation (test files), No Hardcoded Test Content (test-created content) and JSDoc on Actions (page objects). No Magic Numbers names `playwright.config.ts` as a home for constants.
- `ci-replay` no longer suggests `console.log`, which `npm run lint` rejects; the `helpers` example carries the JSDoc its own rule requires.

### Docs

- The README API example is the real `tests/app/api/login.spec.ts` test (enum endpoint, env credentials) instead of a hardcoded path, and the selector sections match the CSS rule.

---

## v2.0.2 -- ArchQA Colors, a Hero Image That Matches the Command -- 2026-11-13

### Initializer

- **The ArchQA wordmark prints in the brand's sage green** (`#7cae7a`), fading down from a light tint of it, instead of cyan to blue: the exact colors on a 24-bit terminal (`COLORTERM=truecolor` or `24bit`), the nearest 256-color shades elsewhere. Without a TTY or with `NO_COLOR` it stays plain.

### Docs

- **`assets/hero-terminal.svg` shows the documented command**, `npm create agentic-playwright@latest . -- --demo`, run inside `~/my-tests`, and what the initializer prints for it: the ArchQA wordmark in the same sage fade, the five setup steps, `3 passed`, the ready line and the two AI-rules lines, on the brand's dark slate with pale-yellow accents. The image ships in the template, so every project scaffolded from this version carries it in its README.
- The package README shows the same image on npmjs.com.

---

## v2.0.1 -- Two AI Flags, Clearer Commands -- 2026-11-03

### Initializer

- **Two AI flags: Claude Code or the other agents.** `--no-claude` leaves out `.claude/` and `CLAUDE.md`; `--no-agents` now leaves out `.agents/` **and** `.github/prompts/` (Codex, Cursor, GitHub Copilot, ...). `--no-copilot` and `--no-cursor` are deprecated: still accepted, they print a note and prune nothing. The interactive setup asks three questions (was four).
- **A forgotten `--` still works.** `npm create agentic-playwright . --demo` used to lose `--demo` to npm and start the interactive setup; the initializer now reads the flags npm kept back (`npm_config_*`), applies them and shows the command with `--`. npm warns this form will stop working in its next major version, so the docs keep the `--`.
- `--help` exits 0 (it exited 1 without a folder). `--bare --yes` is the documented no-questions form for your own app; `--yes` alone is unchanged.
- Every prompt goes through the input-closed guard: piped input that ends early no longer fails at the URL prompts.

### Docs

- Every command uses `@latest`: without it, `npm create` can reuse an older initializer from the npx cache. The package README and the README quick start show the commands as a table with a line on what the `--` does.
- `template-smoke.yml` scaffolds the agents-pruned variant with `--no-agents` alone.

---

## v2.0.0 -- One Orchestrator, One Skill Tree, Every AI Tool -- 2026-11-02

### Rules layer (BREAKING: the project layout changes)

- **`AGENTS.md` is the one orchestrator** for Claude Code, Codex, Cursor and GitHub Copilot: the Constitution (14 MUST, 5 SHOULD, 17 WON'T, one line each), the workflow and the Skills Index. `CLAUDE.md` imports it with `@AGENTS.md` and adds a short Claude Code block.
- **One skill tree.** `.claude/skills/` is canonical; `.agents/skills/` is generated from it byte for byte (`npm run skills:sync`) and read by Codex, Cursor and Copilot. `.cursor/`, `.github/instructions/`, `.github/skills/` and `.github/copilot-instructions.md` are gone.
- **The fifteen scaffold skills are rewritten** to one authoring standard: a short `Critical` block, a numbered `Procedure`, `References` read on demand. The `examples.md` and `troubleshooting.md` references are folded in or removed.

### Constitution hook

- Eighteen rules (was seven), each mapped to the Constitution row it enforces: hard waits (including `timers/promises`), loose schemas, XPath, `@playwright/test` imports, JSON or runtime code in static data, unknown, multiple or missing tags, the retired `@functional` tag, tags on `test.describe()`, manual page-object instantiation, hardcoded URLs, JSDoc on locator getters, inline assertion text, inline universal invalids and inline `eslint-disable`.
- An `Edit` is judged on the file it produces, and comments are ignored. A new page object needs a fresh `playwright-cli` exploration (`scripts/playwright-cli.sh` records it). The hook layer itself is write-protected. A crash fails closed.
- **`--scan` mode** runs the same rules over files on disk: pre-commit scans the staged TypeScript and static data and `lint.yml` the changed ones, so Codex, Cursor and Copilot meet the rules at commit time.

### Gates, pre-commit and CI

- `npm run check:skills` runs eight gates: `check:agents-md` (budget, index, markers), `check:skills-sync` (the generated tree, content and modes), `check:skills-shape` (authoring caps), `skills:verify` (vendored skill directories hashed against `skills-lock.json`), `check:skills-drift` (Constitution rows, skill anchors, hook rule ids), `check:skills-references`, `check:skills-headings` (cross-skill step pointers) and `check:skills-crossrefs`. The gates also pass in a project created with `--no-claude` or `--skip-git`.
- `.husky/pre-commit`: lint-staged (`--max-warnings 0`), the scan (paths NUL-delimited, so names with spaces are scanned whole), the rule-layer gates when their inputs are staged (deletions and renames included), the version gate.
- `lint.yml` lints the changed TypeScript plus the scan, and the whole project when a lint rule changed. It also fails when `node_modules/playwright` is not the `@playwright/test` version or `npx playwright test --list` collects no tests (no browser, no env file). `npm run check:version` also asserts the two root versions in `package-lock.json`.
- `.gitattributes` checks out every text file with LF on every platform (Windows batch files with CRLF): the gates read Markdown and JSON byte for byte, so a `core.autocrlf=true` checkout no longer turns them red.

### Product fixes

- The API access token reaches every worker: the setup writes `.auth/app/apiAccessToken.json` and a worker-scoped fixture loads it.
- Two setup projects: `setup-api` mints the token over HTTP, `setup-ui` signs in through the browser. The `api` project depends on `setup-api` only, so an API run never launches a browser.
- `resetStorageState` also clears `localStorage` and `sessionStorage`; the config objects are typed (`!` on guaranteed reads); `UnauthorizedResponseSchema` accepts both 401 bodies of the demo API; describe titles may read `METHOD /path`.

### Dependencies

- Every pin at its latest release: `@playwright/test` 1.64.1, `playwright` 1.64.1 (pinned so the CLI's alpha cannot replace the test runner), `@playwright/cli` 0.1.23 (vendored skill refreshed), ESLint 10.14, typescript-eslint 8.72, zod 4.6, dotenv 18, faker 10.6, lint-staged 17.6. `eslint-define-config` is dropped. Node 22 is required (`engines`, `setup.sh`, CI).
- After `npm install`, run `npm run playwright-cli:install-browsers` once. The installer now puts Chromium in the cache the `playwright-cli` wrapper reads (`PLAYWRIGHT_CLI_BROWSERS_PATH`, default `~/.cache/playwright-cli-browsers`) on every machine; before, a local run used Playwright's default folder and the wrapper reported "Browser chromium not installed".

### Initializer

- `--no-claude` prunes `.claude/` and `CLAUDE.md` (`AGENTS.md` stays); the new `--no-agents` prunes `.agents/`; `--no-copilot` prunes the PR-review prompt only; `--no-cursor` is accepted and prunes nothing (Cursor reads `AGENTS.md` and `.agents/skills/`). `--no-claude` with `--no-agents` keeps `.agents/`: `AGENTS.md` always ships and needs one skill tree.
- "Next steps" lists `npm run playwright-cli:install-browsers`.
- The template smoke test scaffolds both pruned variants and runs the eight gates in each.

### Updating an existing project

The initializer never updates an existing project. By hand:

- Delete `.cursor/`, `.github/instructions/`, `.github/skills/` and `.github/copilot-instructions.md`.
- Copy from this release: `AGENTS.md`, `CLAUDE.md`, `.gitattributes`, `.gitignore`, `.prettierignore`, `.devcontainer/`, `.claude/skills/`, `.claude/scripts/enforce_constitution.py`, `.claude/settings.json`, `.agents/README.md`, `scripts/` (every gate script and `rules-manifest.txt`), `.husky/pre-commit`, `.github/workflows/lint.yml`, `skill-lint.yml` and `playwright.yml`, `scripts/install-playwright-cli-browsers.js`, `.github/prompts/pr-reviewer.prompt.md`, `skills-lock.json`, `eslint.config.mts`, `playwright.config.ts`, both setup files under `tests/app/` (`auth.setup.ts` and the new `auth-api.setup.ts`), `helpers/app/createStorageState.ts`, `fixtures/api/api-request-fixture.ts`, `fixtures/pom/page-object-fixture.ts`, `fixtures/api/schemas/util/errorResponseSchema.ts`, `pages/components/navigation.component.ts` (its locator getters lose their JSDoc, which the hook now rejects), `config/`, `enums/app/app.ts`.
- Take the `scripts`, `devDependencies`, `dependencies`, `lint-staged` and `engines` blocks of `package.json`, then `npm install`, `npm run playwright-cli:install-browsers`, `npm run skills:sync`, `npm run check:skills`, `npm run lint`.

## v1.0.2 -- Template Payload Excludes Repo-Only CI -- 2026-09-21

- **Scaffolded projects no longer inherit repo-only CI.** `prepack.js` now excludes `.github/workflows/template-smoke.yml`, `.github/workflows/release.yml`, and `.github/FUNDING.yml` from the bundled template. Projects created with 1.0.1 shipped the template smoke workflow, which fails on every push because it expects `packages/create-agentic-playwright/` — delete those two workflow files in an existing project to fix it.
- **New `Lint` workflow** (`.github/workflows/lint.yml`) runs `tsc`, ESLint, and Prettier on the repository itself, so formatting drift from web-UI edits fails with an obvious name. Ships with scaffolded projects too. The generated `packages/create-agentic-playwright/template/` directory is now excluded from `tsconfig.json` and ESLint, so a local `npm pack` no longer doubles the lint surface.
- **Release workflow is idempotent.** Re-pushing an already-published tag skips `npm publish` instead of failing with "cannot publish over the previously published versions".
- **Prettier-version-agnostic skill examples.** `type-safety` code fences no longer use `{ /* ... */ }` object bodies, which Prettier 3.8 and 3.9 format differently and would have broken the template smoke gate on the next Prettier bump.

## v1.0.1 -- Silence dotenv v17 Banners -- 2026-08-13

- **dotenv v17 promotional banners silenced.** `dotenv.config()` now passes `quiet: true` — v17 (pulled in via dependency updates) prints "injected env" lines with rotating sponsor ads into every Playwright run.
- Release workflow runs on Node 24 (`npm@latest` no longer supports Node 20).

## v1.0.0 -- Initial Public Release -- 2026-08-13

The first public release of **Agentic Playwright** — a production-grade Playwright + TypeScript scaffold for agentic testing, with a harness for all major AI coding agents baked in.

### What's included

- **Scaffold core** — dependency-injected page objects, API testing with runtime-validated Zod contracts, test data factories (Faker + Zod), static boundary/invalid datasets, enums as the single source of truth for endpoints, routes, and messages.
- **AI harness** — a Constitution (`CLAUDE.md`) plus 17 detailed skills covering selectors, page objects, fixtures, test standards, type safety, data strategy, API testing, debugging, refactoring, PR review, and an 8-phase AI-native workflow with a confidence gate.
- **Multi-agent support** — parallel rule trees for Claude Code (`.claude/`), Cursor (`.cursor/`), and GitHub Copilot (`.github/`), kept consistent by lint and cross-reference gates.
- **Exploration-first UI testing** — mandatory live-app exploration via `playwright-cli` before any page object or selector is generated.
- **Constitution enforcement hook** — write-time guard that checks generated code against the scaffold's forbidden patterns.
- **PR review skill** — reviews a branch against the scaffold's own rules: routed skills, verification (ESLint / Prettier / tsc / affected tests), tiered findings with confidence.
- **Quality gates** — skill linting, cross-reference checks, rules-drift detection, and version single-sourcing, wired into CI and husky hooks.
- **Dev Container** — pre-warmed browser and npm caches for near-instant onboarding.
