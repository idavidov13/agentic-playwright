# Changelog

All notable changes to Agentic Playwright are documented here. Entries are listed in reverse chronological order (newest first).

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
